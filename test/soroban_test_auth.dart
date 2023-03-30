import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  SorobanServer sorobanServer =
      SorobanServer("https://horizon-futurenet.stellar.cash/soroban/rpc");

  StellarSDK sdk = StellarSDK.FUTURENET;

  KeyPair submitterKeypair = KeyPair.random();
  String submitterId = submitterKeypair.accountId;
  KeyPair invokerKeypair = KeyPair.random();
  String invokerId = invokerKeypair.accountId;

  String authContractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/auth.wasm";
  String? authContractWasmId;
  String? authContractId;

  setUp(() async {
    sorobanServer.enableLogging = true;
    sorobanServer.acknowledgeExperimental = true;
    GetAccountResponse accountResponse =
        await sorobanServer.getAccount(submitterId);
    if (accountResponse.accountMissing) {
      await FuturenetFriendBot.fundTestAccount(submitterId);
    }
    await sorobanServer.getAccount(invokerId);
    if (accountResponse.accountMissing) {
      await FuturenetFriendBot.fundTestAccount(invokerId);
    }
  });

  // poll until success or error
  Future<GetTransactionStatusResponse> pollStatus(String transactionId) async {
    var status = SorobanServer.TRANSACTION_STATUS_PENDING;
    GetTransactionStatusResponse? statusResponse;
    while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
      await Future.delayed(const Duration(seconds: 3), () {});
      statusResponse = await sorobanServer.getTransactionStatus(transactionId);
      assert(statusResponse.error == null);
      status = statusResponse.status!;
      if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
        assert(statusResponse.resultError != null);
        print(statusResponse.resultError?.message);
        assert(false);
      } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
        assert(statusResponse.results != null);
        assert(statusResponse.results!.isNotEmpty);
      }
    }
    return statusResponse!;
  }

  group('all tests', () {
    test('test install auth contract', () async {
      // load account
      GetAccountResponse submitter =
          await sorobanServer.getAccount(submitterId);
      assert(!submitter.isErrorResponse);

      // load contract wasm file
      Uint8List contractCode = await Util.readFile(authContractPath);

      // create transaction for installing the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInstallingContractCode(contractCode)
              .build();
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to obtain the footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(!simulateResponse.isErrorResponse);
      assert(simulateResponse.footprint != null);

      // set footprint and sign transaction
      transaction.setFootprint(simulateResponse.footprint!);
      transaction.sign(submitterKeypair, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(!sendResponse.isErrorResponse);
      assert(sendResponse.resultError == null);

      GetTransactionStatusResponse statusResponse =
          await pollStatus(sendResponse.transactionId!);
      authContractWasmId = statusResponse.getWasmId();

      assert(authContractWasmId != null);
    });

    test('test create auth contract', () async {
      assert(authContractWasmId != null);

      // reload account for current sequence nr
      GetAccountResponse submitter =
          await sorobanServer.getAccount(submitterId);
      assert(!submitter.isErrorResponse);

      // build the operation for creating the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forCreatingContract(authContractWasmId!)
              .build();

      // build the transaction for creating the contract
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // first simulate to obtain the footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(!simulateResponse.isErrorResponse);
      assert(simulateResponse.resultError == null);

      // set footprint & sign
      transaction.setFootprint(simulateResponse.footprint!);
      transaction.sign(submitterKeypair, Network.FUTURENET);

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(!sendResponse.isErrorResponse);
      assert(sendResponse.resultError == null);

      GetTransactionStatusResponse statusResponse =
          await pollStatus(sendResponse.transactionId!);
      authContractId = statusResponse.getContractId();
      assert(authContractId != null);
    });

    test('test invoke auth account', () async {
      // invoke contract
      // If submitter_kp and invoker are the same account, the submission will fail
      // because in that case we do not need address, nonce and signature in auth
      // or we have to change the footprint
      // See https://discord.com/channels/897514728459468821/1078208197283807305

      assert(authContractId != null);

      // reload account for sequence number
      GetAccountResponse submitter =
          await sorobanServer.getAccount(submitterId);
      assert(!submitter.isErrorResponse);

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "auth";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      AuthorizedInvocation rootInvocation =
          AuthorizedInvocation(authContractId!, functionName, args: args);
      int nonce = await sorobanServer.getNonce(invokerId, authContractId!);
      ContractAuth contractAuth =
          ContractAuth(rootInvocation, address: invokerAddress, nonce: nonce);
      contractAuth.sign(invokerKeypair, Network.FUTURENET);

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInvokingContract(
              authContractId!, functionName,
              functionArguments: args, contractAuth: [contractAuth]).build();
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to get footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);

      // set footprint and sign
      transaction.setFootprint(simulateResponse.footprint!);
      transaction.sign(submitterKeypair, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send the transaction
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.transactionId != null);
      assert(sendResponse.status != null);
      assert(sendResponse.resultError == null);

      GetTransactionStatusResponse statusResponse =
          await pollStatus(sendResponse.transactionId!);
      String status = statusResponse.status!;
      assert(status == SorobanServer.TRANSACTION_STATUS_SUCCESS);

      assert(statusResponse.getResultValue()?.getMap() != null);
      List<XdrSCMapEntry> map = statusResponse.getResultValue()!.getMap()!;
      if (map.length > 0) {
        for (XdrSCMapEntry entry in map) {
          Address address = Address.fromXdr(entry.key.obj!.address!);
          print("{" +
              address.accountId! +
              ", " +
              entry.val.u32!.uint32.toString() +
              "}");
        }
      }

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.transactionId!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.transactionId!)
          .execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert(operationResponse.footprint ==
            simulateResponse.footprint?.toBase64EncodedXdrString());
        assert(operationResponse.parameters != null &&
            operationResponse.parameters!.length > 0);
      } else {
        assert(false);
      }
    });

    test('test invoke auth invoker', () async {
      // See https://soroban.stellar.org/docs/learn/authorization#transaction-invoker
      // See https://discord.com/channels/897514728459468821/1078208197283807305

      // submitter and invoker use are thw same
      // so we should not need its address & nonce in contract auth and no need to sign

      assert(authContractId != null);

      // reload account for sequence number
      GetAccountResponse invoker = await sorobanServer.getAccount(invokerId);
      assert(!invoker.isErrorResponse);

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "auth";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      AuthorizedInvocation rootInvocation =
          AuthorizedInvocation(authContractId!, functionName, args: args);

      //int nonce = await sorobanServer.getNonce(invokerId, authContractId!);
      //ContractAuth contractAuth = ContractAuth(rootInvocation, address: invokerAddress, nonce: nonce);
      //contractAuth.sign(invokerKeypair, Network.FUTURENET);
      ContractAuth contractAuth = ContractAuth(rootInvocation);

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInvokingContract(
              authContractId!, functionName,
              functionArguments: args, contractAuth: [contractAuth]).build();
      Transaction transaction =
          new TransactionBuilder(invoker).addOperation(operation).build();

      // simulate first to get footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);

      // set footprint and sign
      transaction.setFootprint(simulateResponse.footprint!);
      transaction.sign(invokerKeypair, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send the transaction
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.resultError == null);

      GetTransactionStatusResponse statusResponse =
          await pollStatus(sendResponse.transactionId!);
      String status = statusResponse.status!;
      assert(status == SorobanServer.TRANSACTION_STATUS_SUCCESS);

      assert(statusResponse.getResultValue()?.getMap() != null);
      List<XdrSCMapEntry> map = statusResponse.getResultValue()!.getMap()!;
      if (map.length > 0) {
        for (XdrSCMapEntry entry in map) {
          Address address = Address.fromXdr(entry.key.obj!.address!);
          print("{" +
              address.accountId! +
              ", " +
              entry.val.u32!.uint32.toString() +
              "}");
        }
      }
    });

    test('test invoke with auth from simulation', () async {
      // in this test we use the contract auth from the simulation response.

      assert(authContractId != null);

      // reload account for sequence number
      GetAccountResponse submitter =
          await sorobanServer.getAccount(submitterId);
      assert(!submitter.isErrorResponse);

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "auth";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInvokingContract(
                  authContractId!, functionName,
                  functionArguments: args)
              .build();
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to get footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.contractAuth != null);

      // set footprint, contract auth and sign
      transaction.setFootprint(simulateResponse.footprint!);
      List<ContractAuth> contractAuth = simulateResponse.contractAuth!;
      for (ContractAuth auth in contractAuth) {
        auth.sign(invokerKeypair, Network.FUTURENET);
      }
      transaction.setContractAuth(contractAuth);
      transaction.sign(submitterKeypair, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send the transaction
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.transactionId != null);
      assert(sendResponse.status != null);
      assert(sendResponse.resultError == null);

      GetTransactionStatusResponse statusResponse =
          await pollStatus(sendResponse.transactionId!);
      String status = statusResponse.status!;
      assert(status == SorobanServer.TRANSACTION_STATUS_SUCCESS);

      assert(statusResponse.getResultValue()?.getMap() != null);
      List<XdrSCMapEntry> map = statusResponse.getResultValue()!.getMap()!;
      if (map.length > 0) {
        for (XdrSCMapEntry entry in map) {
          Address address = Address.fromXdr(entry.key.obj!.address!);
          print("{" +
              address.accountId! +
              ", " +
              entry.val.u32!.uint32.toString() +
              "}");
        }
      }

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.transactionId!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.transactionId!)
          .execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert(operationResponse.footprint ==
            simulateResponse.footprint?.toBase64EncodedXdrString());
        assert(operationResponse.parameters != null &&
            operationResponse.parameters!.length > 0);
      } else {
        assert(false);
      }
    });
  });
}