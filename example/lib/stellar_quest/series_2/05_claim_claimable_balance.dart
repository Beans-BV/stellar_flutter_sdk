import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> claimClaimableBalance({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SAW74SJ4ERDAKW4GSL63ASQAN7EVFCI4A44JMRKPPGAP6ROGPBL6SN3J",
    // GAS4N4UW4CU24AIVQIIGDW6ENUYZUVZ7Z3MH5GVYGQHVKXLJ2GBDP6RQ
  );
  // await FriendBot.fundTestAccount(sourceKeyPair.accountId);

  final claimableBalance = await getLatestClaimbaleBalance(sdk, sourceKeyPair);

  final claimClaimableBalanceBuilder = ClaimClaimableBalanceOperationBuilder(
    claimableBalance.balanceId,
  );

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(claimClaimableBalanceBuilder.build());

  final transaction = transactionBuilder.build()..sign(sourceKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}

Future<ClaimableBalanceResponse> getLatestClaimbaleBalance(
  StellarSDK sdk,
  KeyPair sourceKeyPair,
) async {
  final claimableBalances = await sdk.claimableBalances
      .forClaimant(sourceKeyPair.accountId)
      .order(RequestBuilderOrder.DESC)
      .execute();
  assert(claimableBalances.records.isNotEmpty);

  return claimableBalances.records.first;
}
