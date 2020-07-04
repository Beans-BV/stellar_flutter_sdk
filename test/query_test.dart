@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('test query accounts', () async {
    KeyPair accountKeyPair = KeyPair.random();
    String accountId = accountKeyPair.accountId;
    await FriendBot.fundTestAccount(accountId);

    AccountResponse account = await sdk.accounts.account(accountId);
    Page<AccountResponse> accountsForSigner =
        await sdk.accounts.forSigner(accountId).execute();
    assert(accountsForSigner.records.first.accountId == accountId);

    List<KeyPair> testKeyPairs = List<KeyPair>();
    for (int i = 0; i < 3; i++) {
      testKeyPairs.add(KeyPair.random());
    }
    // Create an issuer account and a custom asset to test "accounts.forAsset()"
    KeyPair issuerkp = KeyPair.random();
    String issuerAccountId = issuerkp.accountId;

    TransactionBuilder tb = TransactionBuilder(account, Network.TESTNET);

    CreateAccountOperation createAccount =
        CreateAccountOperationBuilder(issuerAccountId, "5").build();
    tb.addOperation(createAccount);

    for (KeyPair keyp in testKeyPairs) {
      createAccount =
          CreateAccountOperationBuilder(keyp.accountId, "5").build();
      tb.addOperation(createAccount);
    }

    Transaction transaction = tb.build();
    transaction.sign(accountKeyPair);
    SubmitTransactionResponse respone =
        await sdk.submitTransaction(transaction);
    assert(respone.success);

    tb = TransactionBuilder(account, Network.TESTNET);
    for (KeyPair keyp in testKeyPairs) {
      tb.addOperation(SetOptionsOperationBuilder()
          .setSourceAccount(keyp.accountId)
          .setSigner(accountKeyPair.xdrSignerKey, 1)
          .build());
    }
    transaction = tb.build();
    transaction.sign(accountKeyPair);
    for (KeyPair keyp in testKeyPairs) {
      transaction.sign(keyp);
    }

    respone = await sdk.submitTransaction(transaction);
    assert(respone.success);
    accountsForSigner = await sdk.accounts.forSigner(accountId).execute();
    assert(accountsForSigner.records.length == 4);
    accountsForSigner = await sdk.accounts
        .forSigner(accountId)
        .limit(2)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(accountsForSigner.records.length == 2);

    Asset astroDollar = AssetTypeCreditAlphaNum12("ASTRO", issuerAccountId);
    tb = TransactionBuilder(account, Network.TESTNET);
    ChangeTrustOperation ct = ChangeTrustOperationBuilder(astroDollar, "20000")
        .setSourceAccount(accountId)
        .build();
    tb.addOperation(ct);
    for (KeyPair keyp in testKeyPairs) {
      ct = ChangeTrustOperationBuilder(astroDollar, "20000")
          .setSourceAccount(keyp.accountId)
          .build();
      tb.addOperation(ct);
    }
    transaction = tb.build();
    transaction.sign(accountKeyPair);
    respone = await sdk.submitTransaction(transaction);
    assert(respone.success);
    Page<AccountResponse> accountsForAsset =
        await sdk.accounts.forAsset(astroDollar).execute();
    assert(accountsForAsset.records.length == 4);
    accountsForAsset = await sdk.accounts
        .forAsset(astroDollar)
        .limit(2)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(accountsForAsset.records.length == 2);
  });

  test('test query assets', () async {
    Page<AssetResponse> assetsPage = await sdk.assets
        .assetCode("USD")
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();
    List<AssetResponse> assets = assetsPage.records;
    assert(assets.length > 0 && assets.length < 6);
    for (AssetResponse asset in assets) {
      print("asset issuer: " + asset.assetIssuer);
    }
    String assetIssuer = assets.last.assetIssuer;
    assetsPage = await sdk.assets
        .assetIssuer(assetIssuer)
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assets = assetsPage.records;
    assert(assets.length > 0 && assets.length < 6);
    for (AssetResponse asset in assets) {
      print("asset code: " +
          asset.assetCode +
          " amount:${asset.amount} " +
          "num accounts:${asset.numAccounts}");
    }
  });

  test('test query effects', () async {
    Page<AssetResponse> assetsPage = await sdk.assets
        .assetCode("USD")
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();
    List<AssetResponse> assets = assetsPage.records;
    assert(assets.length > 0 && assets.length < 6);

    String assetIssuer = assets.last.assetIssuer;

    Page<EffectResponse> effectsPage = await sdk.effects
        .forAccount(assetIssuer)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    List<EffectResponse> effects = effectsPage.records;
    assert(effects.length > 0 && effects.length < 4);
    assert(effects.first is AccountCreatedEffectResponse);

    Page<LedgerResponse> ledgersPage =
        await sdk.ledgers.limit(1).order(RequestBuilderOrder.DESC).execute();
    assert(ledgersPage.records.length == 1);
    LedgerResponse ledger = ledgersPage.records.first;
    effectsPage = await sdk.effects
        .forLedger(ledger.sequence)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    effects = effectsPage.records;
    assert(effects.length > 0);

    Page<TransactionResponse> transactionsPage = await sdk.transactions
        .forLedger(ledger.sequence)
        .limit(1)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(transactionsPage.records.length == 1);
    TransactionResponse transaction = transactionsPage.records.first;
    effectsPage = await sdk.effects
        .forTransaction(transaction.hash)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    assert(effects.length > 0);

    Page<OperationResponse> operationsPage = await sdk.operations
        .forTransaction(transaction.hash)
        .limit(1)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(operationsPage.records.length == 1);
    OperationResponse operation = operationsPage.records.first;
    effectsPage = await sdk.effects
        .forOperation(operation.id)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    assert(effects.length > 0);
  });

  test('test query ledgers', () async {
    Page<LedgerResponse> ledgersPage =
        await sdk.ledgers.limit(1).order(RequestBuilderOrder.DESC).execute();
    assert(ledgersPage.records.length == 1);
    LedgerResponse ledger = ledgersPage.records.first;

    LedgerResponse ledger2 = await sdk.ledgers.ledger(ledger.sequence);
    assert(ledger.sequence == ledger2.sequence);
  });

  test('test query fee stats', () async {
    FeeStatsResponse feeStats = await sdk.feeStats.execute();
    assert(feeStats.lastLedger.isNotEmpty);
    assert(feeStats.lastLedgerBaseFee.isNotEmpty);
    assert(feeStats.lastLedgerCapacityUsage.isNotEmpty);
    assert(feeStats.feeCharged.max.isNotEmpty);
    assert(feeStats.feeCharged.min.isNotEmpty);
    assert(feeStats.feeCharged.mode.isNotEmpty);
    assert(feeStats.feeCharged.p10.isNotEmpty);
    assert(feeStats.feeCharged.p20.isNotEmpty);
    assert(feeStats.feeCharged.p30.isNotEmpty);
    assert(feeStats.feeCharged.p40.isNotEmpty);
    assert(feeStats.feeCharged.p50.isNotEmpty);
    assert(feeStats.feeCharged.p60.isNotEmpty);
    assert(feeStats.feeCharged.p70.isNotEmpty);
    assert(feeStats.feeCharged.p80.isNotEmpty);
    assert(feeStats.feeCharged.p90.isNotEmpty);
    assert(feeStats.feeCharged.p95.isNotEmpty);
    assert(feeStats.feeCharged.p99.isNotEmpty);
    assert(feeStats.maxFee.max.isNotEmpty);
    assert(feeStats.maxFee.min.isNotEmpty);
    assert(feeStats.maxFee.mode.isNotEmpty);
    assert(feeStats.maxFee.p10.isNotEmpty);
    assert(feeStats.maxFee.p20.isNotEmpty);
    assert(feeStats.maxFee.p30.isNotEmpty);
    assert(feeStats.maxFee.p40.isNotEmpty);
    assert(feeStats.maxFee.p50.isNotEmpty);
    assert(feeStats.maxFee.p60.isNotEmpty);
    assert(feeStats.maxFee.p70.isNotEmpty);
    assert(feeStats.maxFee.p80.isNotEmpty);
    assert(feeStats.maxFee.p90.isNotEmpty);
    assert(feeStats.maxFee.p95.isNotEmpty);
    assert(feeStats.maxFee.p99.isNotEmpty);
  });

  test('test query offers and order book', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair buyerKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String buyerAccountId = buyerKeipair.accountId;

    await FriendBot.fundTestAccount(buyerAccountId);

    AccountResponse buyerAccount = await sdk.accounts.account(buyerAccountId);
    CreateAccountOperationBuilder caob =
        CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(caob.build())
        .build();
    transaction.sign(buyerKeipair);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    String assetCode = "ASTRO";

    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(astroDollar, "10000");
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ctob.build())
        .build();
    transaction.sign(buyerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    String amountBuying = "100";
    String price = "0.5";

    ManageBuyOfferOperation ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .build();
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(buyerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    List<OfferResponse> offers =
        (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == astroDollar);
    assert(offer.selling == Asset.NATIVE);

    double offerAmount = double.parse(offer.amount);
    double offerPrice = double.parse(offer.price);
    double buyingAmount = double.parse(amountBuying);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    assert(offer.seller.accountId == buyerKeipair.accountId);

    String offerId = offer.id;

    OrderBookResponse orderBook = await sdk.orderBook
        .buyingAsset(astroDollar)
        .sellingAsset(Asset.NATIVE)
        .limit(1)
        .execute();
    offerAmount = double.parse(orderBook.asks.first.amount);
    offerPrice = double.parse(orderBook.asks.first.price);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    Asset base = orderBook.base;
    Asset counter = orderBook.counter;

    assert(base is AssetTypeNative);
    assert(counter is AssetTypeCreditAlphaNum12);

    AssetTypeCreditAlphaNum12 counter12 = counter;
    assert(counter12.code == assetCode);
    assert(counter12.issuerId == issuerAccountId);

    orderBook = await sdk.orderBook
        .buyingAsset(Asset.NATIVE)
        .sellingAsset(astroDollar)
        .limit(1)
        .execute();
    offerAmount = double.parse(orderBook.bids.first.amount);
    offerPrice = double.parse(orderBook.bids.first.price);

    assert((offerAmount * offerPrice).round() == 25);

    base = orderBook.base;
    counter = orderBook.counter;

    assert(counter is AssetTypeNative);
    assert(base is AssetTypeCreditAlphaNum12);

    AssetTypeCreditAlphaNum12 base12 = base;
    assert(base12.code == assetCode);
    assert(base12.issuerId == issuerAccountId);
  });

  test('query trades', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    KeyPair keyPairD = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;
    String accountDId = keyPairD.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
        new CreateAccountOperationBuilder(accountCId, "10").build())
        .addOperation(
        new CreateAccountOperationBuilder(accountBId, "10").build())
        .addOperation(
        new CreateAccountOperationBuilder(accountDId, "10").build())
        .build();
    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
    await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse accountC = await sdk.accounts.account(accountCId);
    AccountResponse accountB = await sdk.accounts.account(accountBId);
    AccountResponse accountD = await sdk.accounts.account(accountDId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);
    Asset ecoAsset = AssetTypeCreditAlphaNum4("ECO", keyPairA.accountId);
    ChangeTrustOperationBuilder ctIOMOp =
    ChangeTrustOperationBuilder(iomAsset, "200999");
    ChangeTrustOperationBuilder ctECOOp =
    ChangeTrustOperationBuilder(ecoAsset, "200999");

    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .build();
    transaction.sign(keyPairC);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .addOperation(ctECOOp.build())
        .build();
    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountD, Network.TESTNET)
        .addOperation(ctECOOp.build())
        .build();
    transaction.sign(keyPairD);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
        PaymentOperationBuilder(accountCId, iomAsset, "100").build())
        .addOperation(
        PaymentOperationBuilder(accountBId, iomAsset, "100").build())
        .addOperation(
        PaymentOperationBuilder(accountBId, ecoAsset, "100").build())
        .addOperation(
        PaymentOperationBuilder(accountDId, ecoAsset, "100").build())
        .build();
    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    ManageSellOfferOperation sellOfferOp =
    ManageSellOfferOperation(ecoAsset, iomAsset, "30", "0.5", "0");
    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(sellOfferOp)
        .build();
    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    PathPaymentStrictSendOperation strictSend =
    PathPaymentStrictSendOperationBuilder(
        iomAsset, "10", accountDId, ecoAsset, "18")
        .build();
    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(strictSend)
        .build();
    transaction.sign(keyPairC);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    bool found = false;
    accountD = await sdk.accounts.account(accountDId);
    for (Balance balance in accountD.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "ECO") {
        assert(double.parse(balance.balance) > 19);
        found = true;
        break;
      }
    }
    assert(found);

    bool tradeExecuted = false;
    // Stream trades.
    var subscription = sdk.trades
        .forAccount(accountBId)
        .cursor("now")
        .stream()
        .listen((response) {
      tradeExecuted = true;
      assert(response.baseAccount == accountBId);
    });

    PathPaymentStrictReceiveOperation strictReceive =
    PathPaymentStrictReceiveOperationBuilder(
        iomAsset, "2", accountDId, ecoAsset, "3")
        .build();
    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(strictReceive)
        .build();
    transaction.sign(keyPairC);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    found = false;
    accountD = await sdk.accounts.account(accountDId);
    for (Balance balance in accountD.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "ECO") {
        assert(double.parse(balance.balance) > 22);
        found = true;
        break;
      }
    }
    assert(found);

    Page<TradeResponse> trades = await sdk.trades.forAccount(accountBId).execute();
    assert(trades.records.length > 0);
    TradeResponse trade = trades.records.first;

    assert(trade.offerId != null);
    assert(trade.baseIsSeller);
    assert(trade.baseAccount == accountBId);
    assert(trade.baseOfferId == trade.offerId);
    assert(double.parse(trade.baseAmount) == 20);
    assert(trade.baseAssetType == "credit_alphanum4");
    assert(trade.baseAssetCode == "ECO");
    assert(trade.baseAssetIssuer == accountAId);

    assert(trade.counterAccount == accountCId);
    assert(trade.counterOfferId != null);
    assert(double.parse(trade.counterAmount) == 10);
    assert(trade.counterAssetType == "credit_alphanum4");
    assert(trade.counterAssetCode == "IOM");
    assert(trade.counterAssetIssuer == accountAId);
    assert(trade.price.numerator == 1);
    assert(trade.price.denominator == 2);

    // wait 3 seconds for the trades event.
    await Future.delayed(const Duration(seconds: 3), () {});
    subscription.cancel();
    assert(tradeExecuted);

  });
}
