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
    // StellarToml toml = await StellarToml.fromDomain(
    //   domain,
    //   httpClient: httpClient,
    //   httpRequestHeaders: httpRequestHeaders,
    // );
    // String? hotswapServer = toml.generalInformation.hotswapServer;
    // checkNotNull(
    //   hotswapServer,
    //   "hotswap server not found in stellar toml of domain " + domain,
    // );
    return Hotswap._(
      _getServerAddress(domain),
      httpClient: httpClient,
      sdk: sdk,
    );
  }

  static String _getServerAddress(String domain) {
    if (domain == 'mykobo.co') {
      return "https://api.mykobo.co/boomerang";
    } else if (domain == 'dev.anchor.mykobo.co') {
      return "https://dev.api.mykobo.co/boomerang";
    }
    return domain;
  }

  Future<List<HotswapRoute>> info() async {
    Uri serverURI = Util.appendEndpointToUrl(_serverAddress, 'info');
    var response = await _httpClient.get(serverURI);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final result = _HotswapInfoResponse.fromJson(json).hotswapRoutes;

    return result;
  }

  Future<Transaction> getAnchorSignedTransaction({
    required String accountId,
    required HotswapRoute hotswapRoute,
    String toAssetTrustLineLimit = ChangeTrustOperationBuilder.MAX_LIMIT,
    String? sponsoringAccountId,
  }) async {
    var account = await _sdk.accounts.account(accountId);

    final txBuilder = TransactionBuilder(account);

    final toAsset = hotswapRoute.toAsset.toAsset();
    final trustDestinationAssetOperation = ChangeTrustOperationBuilder(
      toAsset,
      toAssetTrustLineLimit,
    ).build();

    final hotswapHandlerAccountId = hotswapRoute.toAddress;

    final fromAsset = hotswapRoute.fromAsset.toAsset();
    final fromAssetBalanceObject = account.balances.firstWhere(
      (e) =>
          e.assetCode == fromAsset.code && e.assetIssuer == fromAsset.issuerId,
    );
    // Send from asset to the hotswap server
    final depositSourceAssetOperation = PaymentOperationBuilder(
      hotswapHandlerAccountId,
      fromAsset,
      fromAssetBalanceObject.balance,
    ).build();

    // Receive to asset from hotswap server
    final receiveDestinationAssetOperation = PaymentOperationBuilder(
      accountId,
      toAsset,
      fromAssetBalanceObject.balance, // Ensuring a 1:1 exchange
    ).setSourceAccount(hotswapHandlerAccountId).build();

    final untrustSourceAssetOperation = ChangeTrustOperationBuilder(
      fromAsset,
      '0',
    ).build();

    final sponsored = sponsoringAccountId != null;

    if (sponsored) {
      BeginSponsoringFutureReservesOperation beginSponsoringOperation =
          BeginSponsoringFutureReservesOperationBuilder(accountId)
              .setSourceAccount(sponsoringAccountId!)
              .build();
      txBuilder.addOperation(beginSponsoringOperation);
    }
    txBuilder
        .addOperation(trustDestinationAssetOperation)
        .addOperation(depositSourceAssetOperation)
        .addOperation(receiveDestinationAssetOperation)
        .addOperation(untrustSourceAssetOperation);
    if (sponsored) {
      EndSponsoringFutureReservesOperation endSponsorshipOperation =
          EndSponsoringFutureReservesOperationBuilder()
              .setSourceAccount(accountId)
              .build();
      txBuilder.addOperation(endSponsorshipOperation);
    }
    final transaction = txBuilder.build();

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

class HotswapRoute extends Response {
  final String toAddress;
  final String fromAsset;
  final String toAsset;
  final double minimumAmount;

  HotswapRoute({
    required this.toAddress,
    required this.fromAsset,
    required this.toAsset,
    required this.minimumAmount,
  });

  factory HotswapRoute.fromJson(Map<String, dynamic> json) {
    return HotswapRoute(
      toAddress:
          (json['hotswap_address'] ?? json['receivables_address']) as String,
      fromAsset: (json['from_asset'] ?? json['you_send_asset']) as String,
      toAsset: (json['to_asset'] ?? json['we_send_asset']) as String,
      minimumAmount: double.parse(
        (json['min_amount'] ?? json['minimum_amount']) as String,
      ),
    );
  }
}

class _HotswapInfoResponse {
  final List<HotswapRoute> hotswapRoutes;

  _HotswapInfoResponse({required this.hotswapRoutes});

  factory _HotswapInfoResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('hotswap_routes')) {
      return _HotswapInfoResponse(
        hotswapRoutes: (json['hotswap_routes'] as List)
            .map(
              (route) => HotswapRoute.fromJson(
                route as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } else {
      // Single hotswap case (legacy)
      // TODO: Remove as soon as MYKOBO has updated their implementation
      return _HotswapInfoResponse(
        hotswapRoutes: [
          HotswapRoute.fromJson(json),
        ],
      );
    }
  }
}
