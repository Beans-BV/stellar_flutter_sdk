
## [Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk) 
## Soroban support

The following shows you how to use the Flutter SDK to interact with Soroban. 

### Quick Start

Flutter SDK Soroban support allows you to deploy and to invoke Soroban smart contracts.

To deploy and/or invoke smart contracts with the Flutter SDK use the ```SorobanServer``` class. It connects to a given local or remote Soroban-RPC Server.

Soroban-RPC can be simply described as a “live network gateway for Soroban”. It provides information that the network currently has in its view (i.e. current state). It also has the ability to send a transaction to the network and query the network for the status of previously sent transactions.

You can install your own instance of a Soroban-RPC Server as described [here](https://soroban.stellar.org/docs/getting-started/deploy-to-futurenet). Alternatively, you can use a public remote instance for testing.

The Soroban-RPC API is described [here](https://soroban.stellar.org/api/).

#### Initialize SorobanServer 

Provide the url to the endpoint of the Soroban-RPC server to connect to:

```dart
SorobanServer sorobanServer = SorobanServer("https://soroban-testnet.stellar.org");
```

#### General node health check
```dart
GetHealthResponse healthResponse = await sorobanServer.getHealth();

if (GetHealthResponse.HEALTHY == healthResponse.status) {
   //...
}
```

#### Get account data

You first need an account on Testnet. For this one can use ```FriendBot``` to fund it:

```dart
KeyPair accountKeyPair = KeyPair.random();
String accountId = accountKeyPair.accountId;
await FriendBot.fundTestAccount(accountId);
```

Next you can fetch current information about your Stellar account using the SDK:

```dart
AccountResponse submitter = await sdk.accounts.account(submitterId);
```


#### Deploy your contract

If you want to create a smart contract for testing, you can find the official examples [here](https://github.com/stellar/soroban-examples).
You can also create smart contracts with our AssemblyScript Soroban SDK. Examples can be found [here](https://github.com/Soneso/as-soroban-examples).

There are two main steps involved in the process of deploying a contract. First you need to **upload** the **contract code** and then to **create** the **contract**.

To **upload** the **contract code**, first build a transaction containing the corresponding operation:

```dart
// Create the operation for uploading the contract code (*.wasm file content)
UploadContractWasmHostFunction uploadFunction =
    UploadContractWasmHostFunction(contractCode);

InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(uploadFunction).build();

// Build the transaction
Transaction transaction =
    new TransactionBuilder(account).addOperation(operation).build();
```

Next we need to **simulate** the transaction to obtain the **soroban transaction data** and the **resource fee** needed for final submission.

```dart
// Simulate first to obtain the footprint
var request = new SimulateTransactionRequest(transaction);
SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(request);
```
On success, one can find the **soroban transaction data** and the  **resource fee** in the response. Next we need to set the **soroban transaction data** and the **resource fee** to our transaction, then **sign** the transaction and send it to the network using the ```SorobanServer```:

```dart
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.sign(accountKeyPair, Network.TESTNET);

// send transaction to soroban rpc server
SendTransactionResponse sendResponse =
    await sorobanServer.sendTransaction(transaction);
```

On success, the response contains the id and status of the transaction:

```dart
if (sendResponse.error == null) {
  print("Transaction Id: ${sendResponse.hash}");
  print("Status: ${sendResponse.status}"); // PENDING
}
```

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransaction``` request:

```dart
// Fetch transaction 
GetTransactionResponse transactionResponse =
    await sorobanServer.getTransaction(transactionId);

String status = transactionResponse.status;

if (GetTransactionResponse.STATUS_NOT_FOUND == status) {
  // try again later ...
} else if (GetTransactionResponse.STATUS_SUCCESS == status) {
  // continue with creating the contract ...
  String contractWasmId = transactionResponse.getWasmId();
  // ...
} else if (GetTransactionResponse.STATUS_FAILED == status) {
  // handle error ...
}
```

Hint: If you experience an error with the transaction result ```txInternalError``` it is most likely that a ledger entry used in the transaction has expired. You can fix it by restoring the footprint (see this [example](https://github.com/Soneso/stellar_flutter_sdk/blob/9a15982ac862bdcab33713184c800065e573f39b/test/soroban_test.dart#L57) in the soroban test of the SDK).

If the transaction was successful, the status response contains the ```wasmId``` of the installed contract code. We need the ```wasmId``` in our next step to **create** the contract:

```dart
// Build the operation for creating the contract
CreateContractHostFunction function = CreateContractHostFunction(
    Address.forAccountId(accountId), contractWasmId);
InvokeHostFunctionOperation operation =
    InvokeHostFuncOpBuilder(function).build();

// Build the transaction for creating the contract
Transaction transaction = new TransactionBuilder(account)
    .addOperation(operation).build();

// First simulate to obtain the transaction data + resource fee
var request = new SimulateTransactionRequest(transaction);
SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(request);

// set transaction data, add resource fee & auth and sign transaction
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.setSorobanAuth(simulateResponse.sorobanAuth);
transaction.sign(accountKeyPair, Network.TESTNET);

// Send the transaction to the network.
SendTransactionResponse sendResponse =
    await sorobanServer.sendTransaction(transaction);

if (sendResponse.error == null) {
  print("Transaction Id: ${sendResponse.hash}");
  print("Status: ${sendResponse.status}"); // pending
}
```

As you can see, we use the ```wasmId``` to create the operation and the transaction for creating the contract. After simulating, we obtain the transaction data and auth to be set in the transaction. Next, sign the transaction and send it to the Soroban-RPC Server. The transaction status will be "pending", so we need to wait a bit and poll for the current status:

```dart
// Fetch transaction 
GetTransactionResponse transactionResponse =
    await sorobanServer.getTransaction(transactionId);

String status = transactionResponse.status;

if (GetTransactionResponse.STATUS_SUCCESS == status) {
  // contract successfully deployed!
  contractId = transactionResponse.getContractId();
}
```

Success!

#### Get Ledger Entry

The Soroban-RPC server also provides the possibility to request values of ledger entries directly. It will allow you to directly inspect the current state of a contract, a contract’s code, or any other ledger entry. 

For example, to fetch contract wasm byte-code, use the ContractCode ledger entry key:

```dart
XdrLedgerKey ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
ledgerKey.contractCode = XdrLedgerKeyContractCode(XdrHash(Util.hexToBytes(wasmId)),
    XdrContractEntryBodyType.DATA_ENTRY);

GetLedgerEntriesResponse ledgerEntriesResponse =
    await getLedgerEntries([ledgerKey.toBase64EncodedXdrString()]);
```

If you already have a contractId you can load the code as follows:

```dart
XdrContractCodeEntry? cCodeEntry = await sorobanServer.loadContractCodeForContractId(contractId);

if (cCodeEntry != null) {
    Uint8List sourceCode = cCodeEntry.body.code!.dataValue;
}
```

If you have a wasmId:

```dart
XdrContractCodeEntry? cCodeEntry = await sorobanServer.loadContractCodeForWasmId(wasmId);
```

#### Invoking a contract

Now, that we successfully deployed our contract, we are going to invoke it using the Flutter SDK.

First let's have a look to a simple (hello word) contract created with the Rust Soroban SDK. The code and instructions on how to build it, can be found in the official [soroban docs](https://soroban.stellar.org/docs/getting-started/hello-world).

*Hello Word contract code:*

```rust
impl HelloContract {
    pub fn hello(env: Env, to: Symbol) -> Vec<Symbol> {
        vec![&env, symbol_short!("Hello"), to]
    }
}
```

It's only function is called ```hello``` and it accepts a ```symbol``` as an argument. It returns a ```vector``` containing two symbols.

To invoke the contract with the Flutter SDK, we first need to build the corresponding operation and transaction:


```dart
// Name of the function to be invoked
String functionName = "hello";

// Prepare the argument (Symbol)
XdrSCVal arg = XdrSCVal.forSymbol("friend");

// Prepare the "invoke" operation
InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
    contractId!, functionName, arguments: [arg]);

InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(hostFunction).build();

// Build the transaction
Transaction transaction =
    new TransactionBuilder(account).addOperation(operation).build();
```

Next we need to **simulate** the transaction to obtain the **soroban transaction data** and **resource fee** needed for final submission:

```dart
// Simulate first to obtain the footprint
var request = new SimulateTransactionRequest(transaction);
SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(request);
```
On success, one can find the **soroban transaction data** and the  **resource fee** in the response. Next we need to set it to our transaction, **sign** the transaction and send it to the network using the ```SorobanServer```:

```dart
// set transaction data, add resource fee and sign transaction
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.sign(accountKeyPair, Network.TESTNET);

// send transaction to soroban rpc server
SendTransactionResponse sendResponse =
    await sorobanServer.sendTransaction(transaction);
```

On success, the response contains the id and status of the transaction:

```dart
if (sendResponse.error == null) {
  print("Transaction Id: ${sendResponse.hash}");
  print("Status: ${sendResponse.status}"); // pending
}
```

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransactionStatus``` request:

```dart
// Fetch transaction 
GetTransactionResponse transactionResponse =
    await sorobanServer.getTransaction(transactionId);

String status = transactionResponse.status;

if (GetTransactionResponse.STATUS_NOT_FOUND == status) {
  // try again later ...
} else if (GetTransactionResponse.STATUS_SUCCESS == status) {
  // success
  // ...
} else if (GetTransactionResponse.STATUS_FAILED == status) {
  // handle error ...
}
```

If the transaction was successful, the status response contains the result:

```dart
// Get the result value
XdrSCVal resVal = transactionResponse.getResultValue()!;

// Extract the Vector
List<XdrSCVal>? vec = resValO.vec;

// Print result
if (vec != null && vec.length > 1) {
  print("[${vec[0].sym}, ${vec[1].sym}]");
  // [Hello, friend]
}
```

Success!

#### Deploying Stellar Asset Contract (SAC)

The Flutter SDK also provides support for deploying the build-in [Stellar Asset Contract](https://soroban.stellar.org/docs/advanced-tutorials/stellar-asset-contract) (SAC). The following operations are available for this purpose:

1. Deploy SAC with source account:

```dart
DeploySACWithSourceAccountHostFunction function =
    DeploySACWithSourceAccountHostFunction(
        Address.forAccountId(accountId));

InvokeHostFunctionOperation operation =
    InvokeHostFuncOpBuilder(function).build();

//...
// set transaction data, add resource fee & auth and sign transaction
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.setSorobanAuth(simulateResponse.sorobanAuth);
transaction.sign(accountKeyPair, Network.FUTURENET);
```

2. Deploy SAC with asset:

```dart
InvokeHostFunctionOperation operation =
    InvokeHostFuncOpBuilder(DeploySACWithAssetHostFunction(asset))
        .build();
```

#### Soroban Authorization

The Flutter SDK provides support for the [Soroban Authorization Framework](https://soroban.stellar.org/docs/fundamentals-and-concepts/authorization).
The SDK's implementation can be found [here](https://github.com/Soneso/stellar_flutter_sdk/blob/master/lib/src/soroban/soroban_auth.dart).

To provide authorization you can add a list of `SorobanAuthorizationEntry` to the transaction before sending it.

```dart
transaction.setSorobanAuth(myAuthList);
```

The easiest way to do this is to use the auth data generated by the simulation.

```dart
transaction.setSorobanAuth(simulateResponse.sorobanAuth);
```
But you can also compose the authorization entries by yourself.

If the entries need to be signed you can do it as follows:
```dart
// sign auth
List<SorobanAuthorizationEntry>? auth = simulateResponse.sorobanAuth;
assert(auth != null);

GetLatestLedgerResponse latestLedgerResponse = await sorobanServer.getLatestLedger();

for (SorobanAuthorizationEntry a in auth!) {
  // update signature expiration ledger
  a.credentials.addressCredentials!.signatureExpirationLedger =
      latestLedgerResponse.sequence! + 10;
  // sign
  a.sign(invokerKeypair, Network.TESTNET);
}

transaction.setSorobanAuth(auth);
```

One can find multiple examples in the [Soroban Auth Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_auth.dart) and [Soroban Atomic Swap Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_atomic_swap.dart) of the SDK.

#### Get Events

The Soroban-RPC server provides the possibility to request contract events. 

You can use the Flutter SDK to request events like this:

```dart
TopicFilter topicFilter = TopicFilter(
    ["*", XdrSCVal.forSymbol('increment').toBase64EncodedXdrString()]);

EventFilter eventFilter = EventFilter(
    type: "contract", contractIds: [contractId], topics: [topicFilter]);

GetEventsRequest eventsRequest =
    GetEventsRequest(startLedger, filters: [eventFilter]);

GetEventsResponse eventsResponse =
    await sorobanServer.getEvents(eventsRequest);
```

contractId must currently start with "C...". If you only have the hex value you can encode it with: `StrKey.encodeContractIdHex(contractId)`

Find the complete code in the [Soroban Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test.dart).

#### Hints and Tips

You can find the working code and more in the [Soroban Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test.dart), [Soroban Auth Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_auth.dart) and [Soroban Atomic Swap Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_atomic_swap.dart) of the Flutter SDK. The used wasm byte-code files can be found in the [test/wasm](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/wasm/) folder.

Because Soroban and the Flutter SDK support for Soroban are in development, errors may occur. For a better understanding of an error you can enable the ```SorobanServer``` logging:

```dart
server.enableLogging = true;
```
This will log the responses received from the Soroban-RPC server.

If you find any issues please report them [here](https://github.com/Soneso/stellar_flutter_sdk/issues). It will help us to improve the SDK.

### Soroban contract parser

The soroban contract parser allows you to access the contract info stored in the contract bytecode.
You can access the environment metadata, contract spec and contract meta.

The environment metadata holds the interface version that should match the version of the soroban environment host functions supported.

The contract spec contains a `XdrSCSpecEntry` for every function, struct, and union exported by the contract.

In the contract meta, contracts may store any metadata in the entries that can be used by applications and tooling off-network.

You can access the parser directly if you have the contract bytecode:

```dart
var byteCode = await Util.readFile("path to .wasm file");
var contractInfo = SorobanContractParser.parseContractByteCode(byteCode);
```

Or you can use `SorobanServer` methods to load the contract code form the network and parse it.

By contract id:
```dart
var contractInfo = await sorobanServer.loadContractInfoForContractId(contractId);
```

By wasm id:
```dart
var contractInfo = await sorobanServer.loadContractInfoForWasmId(wasmId);
```

The parser returns a `SorobanContractInfo` object containing the parsed data.
In [soroban_test_parser.dart](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_parser.dart#L192) you can find a detailed example of how you can access the parsed data.
