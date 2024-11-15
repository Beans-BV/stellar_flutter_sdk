// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/extensions/extensions.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Hotswap {
  final String _serverAddress;
  final http.Client _httpClient;
  final StellarSDK _sdk;
  final bool _isClientInternal;

  Hotswap._(
    String serverAddress, {
    required StellarSDK sdk,
    http.Client? httpClient,
  })  : _sdk = sdk,
        _isClientInternal = httpClient == null,
        _httpClient = httpClient ?? http.Client(),
        _serverAddress = serverAddress;

  static Future<Hotswap> fromDomain(
    String domain, {
    required StellarSDK sdk,
    http.Client? httpClient,
  }) async {
    StellarToml toml = await StellarToml.fromDomain(
      domain,
      httpClient: httpClient,
    );
    String? hotswapServer = toml.generalInformation.hotswapServer;
    checkNotNull(
      hotswapServer,
      "hotswap server not found in stellar toml of domain " + domain,
    );
    return Hotswap._(
      hotswapServer!,
      httpClient: httpClient,
      sdk: sdk,
    );
  }

  Future<List<HotswapRoute>> info() async {
    Uri serverURI = Util.appendEndpointToUrl(_serverAddress, 'info');
    var response = await _httpClient.get(serverURI);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final result = _HotswapInfoResponse.fromJson(json).hotswapRoutes;

    return result;
  }

  Future<Transaction> buildTransaction({
    required String accountId,
    required HotswapRoute hotswapRoute,
    String toAssetTrustLineLimit = ChangeTrustOperationBuilder.MAX_LIMIT,
    String? sponsoringAccountId,
  }) async {
    var account = await _sdk.accounts.account(accountId);

    final fromAsset = hotswapRoute.youSendAsset.toAsset();
    final fromAssetBalanceObject = account.balances.firstWhere(
      (e) =>
          e.assetCode == fromAsset.code && e.assetIssuer == fromAsset.issuerId,
    );
    final isEmptyBalance = fromAssetBalanceObject.balance.toDouble() == 0;
    final isNonEmptyBalance = !isEmptyBalance;

    final toAsset = hotswapRoute.weSendAsset.toAsset();
    final sponsored = sponsoringAccountId != null;

    final txBuilder = TransactionBuilder(account);

    if (sponsored) {
      BeginSponsoringFutureReservesOperation beginSponsoringOperation =
          BeginSponsoringFutureReservesOperationBuilder(accountId)
              .setSourceAccount(sponsoringAccountId)
              .build();
      txBuilder.addOperation(beginSponsoringOperation);
    }

    final trustDestinationAssetOperation = ChangeTrustOperationBuilder(
      toAsset,
      toAssetTrustLineLimit,
    ).build();
    txBuilder.addOperation(trustDestinationAssetOperation);

    // Only create the payment operations if the balance is not empty
    if (isNonEmptyBalance) {
      final hotswapHandlerAccountId = hotswapRoute.hotswapAddress;
      // Send from asset to the hotswap server
      final depositSourceAssetOperation = PaymentOperationBuilder(
        hotswapHandlerAccountId,
        fromAsset,
        fromAssetBalanceObject.balance,
      ).build();
      txBuilder.addOperation(depositSourceAssetOperation);
      // Receive to asset from hotswap server
      final receiveDestinationAssetOperation = PaymentOperationBuilder(
        accountId,
        toAsset,
        fromAssetBalanceObject.balance, // Ensuring a 1:1 exchange
      ).setSourceAccount(hotswapHandlerAccountId).build();
      txBuilder.addOperation(receiveDestinationAssetOperation);
    }

    final untrustSourceAssetOperation = ChangeTrustOperationBuilder(
      fromAsset,
      '0',
    ).build();
    txBuilder.addOperation(untrustSourceAssetOperation);

    if (sponsored) {
      EndSponsoringFutureReservesOperation endSponsorshipOperation =
          EndSponsoringFutureReservesOperationBuilder()
              .setSourceAccount(accountId)
              .build();
      txBuilder.addOperation(endSponsorshipOperation);
    }

    final transaction = txBuilder.build();

    // No payments needs present so we don't need the hotswap server to sign
    // the transaction
    if (isEmptyBalance) {
      return transaction;
    }

    // Send the transaction to the hotswap server if the balance is not empty
    var transactionXdr = transaction.toEnvelopeXdrBase64();
    var hotswapUrl = Util.appendEndpointToUrl(
      _serverAddress,
      'hotswap',
    ).replace(
      queryParameters: {
        'transaction_xdr': transactionXdr,
      },
    );

    final response = await _httpClient.post(hotswapUrl);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get anchor signed transaction: ${response.statusCode}',
      );
    }

    final signedTransactionResponseData =
        jsonDecode(response.body) as Map<String, dynamic>;
    transactionXdr = signedTransactionResponseData['signed_tx_xdr'] as String;

    final signedTransaction = Transaction.fromV1EnvelopeXdr(
      XdrTransactionEnvelope.fromEnvelopeXdrString(
        transactionXdr,
      ).v1!,
    );

    if (!_checkIntegrity(transaction, signedTransaction)) {
      throw Exception(
        'The anchor signed transaction is corrupted: ${response.statusCode}',
      );
    }
    return signedTransaction;
  }

  void dispose() {
    // Close the client if we created it internally
    if (_isClientInternal) {
      _httpClient.close();
    }
  }

  bool _checkIntegrity(
    Transaction originalTransaction,
    Transaction signedTransaction,
  ) {
    final originalOperations = originalTransaction.operations;
    final signedOperations = signedTransaction.operations;

    if (originalOperations.length != signedOperations.length) {
      return false;
    }

    for (int i = 0; i < originalOperations.length; i++) {
      final originalOperationXdrBase64 = originalOperations[i].toXdrBase64();
      final signedOperationXdrBase64 = signedOperations[i].toXdrBase64();
      if (originalOperationXdrBase64 != signedOperationXdrBase64) {
        return false;
      }
    }

    return true;
  }
}

class HotswapRoute {
  final String hotswapAddress;
  final String youSendAsset;
  final String weSendAsset;

  const HotswapRoute({
    required this.hotswapAddress,
    required this.youSendAsset,
    required this.weSendAsset,
  });

  factory HotswapRoute.fromJson(Map<String, dynamic> json) {
    return HotswapRoute(
      hotswapAddress: json['hotswap_address'] as String,
      youSendAsset: json['you_send_asset'] as String,
      weSendAsset: json['we_send_asset'] as String,
    );
  }
}

class _HotswapInfoResponse {
  final List<HotswapRoute> hotswapRoutes;

  const _HotswapInfoResponse({
    required this.hotswapRoutes,
  });

  factory _HotswapInfoResponse.fromJson(Map<String, dynamic> json) {
    return _HotswapInfoResponse(
      hotswapRoutes: (json['hotswap_routes'] as List)
          .map(
            (route) => HotswapRoute.fromJson(
              route as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
