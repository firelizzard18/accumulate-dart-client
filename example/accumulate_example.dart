import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:accumulate_api/accumulate_api.dart';
import 'package:accumulate_api/src/model/address.dart';
import 'package:accumulate_api/src/model/adi.dart';
import 'package:accumulate_api/src/model/keys/keypage.dart';
import 'package:accumulate_api/src/model/tx.dart';
import 'package:test/test.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

@Timeout(Duration(seconds: 300))
void main() {
  group('DevNet Tests', () {
    final testnetAPI = ACMEApiV2("https://testnet.accumulatenetwork.io/", "v2");

    setUp(() async {});

    ///
    ///
    Future<String?> makeFaucetTest() async {
      // Generate some random data for private keys
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      // Additional setup goes here.
      // 1. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey = ed.public(privateKey);

      // 2. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.address = currentURL.getPath();
      liteAccount.URL = currentURL;

      print(liteAccount.address);

      // 3. Initiate API class instance and register address on the network with faucet
      final acmeAPI = ACMEApiV2("http://178.20.158.25:56660/", "v2");

      // 4. Execute Faucet Calls
      final respFaucet = await acmeAPI.callFaucet(liteAccount);
      final sleep = await Future.delayed(Duration(seconds: 4));
      final respFaucet2 = await acmeAPI.callFaucet(liteAccount);
      final sleep2 = await Future.delayed(Duration(seconds: 4));

      List<Transaction> respHistory = await acmeAPI.callGetTokenTransactionHistory(liteAccount);
      for (var i = 0; i < respHistory.length; i++) {
        print("${respHistory[i].txid} |  ${respHistory[i].amount}");
      }
      //respHistory.map((e) => print(e));

      return respFaucet;
    }

    ///
    ///
    Future<String?> makeTransactionsTest() async {
      // Generate some random data for private keys
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      // Additional setup goes here.
      // 1. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey = ed.public(privateKey);

      // 2. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.address = currentURL.getPath();
      liteAccount.URL = currentURL;

      //   2.1 Store associated private key data along with Address structure
      //       internal methods will use it to sign payloads
      liteAccount.puk = HEX.encode(publicKey.bytes);
      liteAccount.pik = privateKey.bytes;
      liteAccount.pikHex = HEX.encode(privateKey.bytes);

      print("From: ${liteAccount.address}");

      // 3. Create Recipient address
      String mnemonic2 = bip39.generateMnemonic();
      Uint8List seed2 = bip39.mnemonicToSeed(mnemonic2);

      var privateKey2 =
          ed.newKeyFromSeed(seed2.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey2 = ed.public(privateKey2);

      Address liteAccountRecipient = Address("", "ACME Account", "");
      AccumulateURL currentURL2 = liteAccountRecipient.generateAddressViaProtocol(publicKey2.bytes, "ACME");
      liteAccountRecipient.address = currentURL2.getPath();
      liteAccountRecipient.URL = currentURL2;

      print("To: ${liteAccountRecipient.address}");

      // 4. Initiate API class instance and register address on the network with faucet
      final acmeAPI = ACMEApiV2("http://178.20.158.25:56660/", "v2");

      // 5. Execute Faucet Calls
      final respFaucet = await acmeAPI.callFaucet(liteAccount);
      final sleep = await Future.delayed(Duration(seconds: 4));
      final respFaucet2 = await acmeAPI.callFaucet(liteAccount);
      final sleep2 = await Future.delayed(Duration(seconds: 4));

      // 6. We need some credits first
      int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final respCredits = await acmeAPI.callAddCredits(liteAccount, 1000, timestamp);
      final sleepC = await Future.delayed(Duration(seconds: 4));

      // 6. Make actual transaction
      int timestampTx = DateTime.now().toUtc().millisecondsSinceEpoch;
      final respTx = await acmeAPI.callCreateTokenTransaction(liteAccount, liteAccountRecipient, "8", timestampTx);
      final sleepT = await Future.delayed(Duration(seconds: 4));

      print(" ${liteAccount.address} ----------------------- ");

      List<Transaction> respHistory = await acmeAPI.callGetTokenTransactionHistory(liteAccount);
      for (var i = 0; i < respHistory.length; i++) {
        print("${respHistory[i].txid} | ${respHistory[i].type} | ${respHistory[i].subtype} | ${respHistory[i].amount}");
      }

      print(" ${liteAccountRecipient.address} ----------------------- ");

      List<Transaction> respHistoryRecipient = await acmeAPI.callGetTokenTransactionHistory(liteAccountRecipient);
      for (var i = 0; i < respHistoryRecipient.length; i++) {
        print(
            "${respHistoryRecipient[i].txid} | ${respHistoryRecipient[i].type} | ${respHistoryRecipient[i].subtype} | ${respHistoryRecipient[i].amount}");
      }

      return respTx;
    }

    ///
    ///
    Future<String?> makeCreditsTest() async {
      // 1. Generate some random data for private keys
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      // 2. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey = ed.public(privateKey);

      // 3. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.address = currentURL.getPath();
      liteAccount.URL = currentURL;

      //   3.1 Store associated private key data along with Address structure
      //       internal methods will use it to sign payloads
      liteAccount.puk = HEX.encode(publicKey.bytes);
      liteAccount.pik = privateKey.bytes;
      liteAccount.pikHex = HEX.encode(privateKey.bytes);

      print(liteAccount.address);

      // 4. Initiate API class instance and register address on the network with faucet
      final acmeAPI = ACMEApiV2("https://testnet.accumulatenetwork.io/", "v2");
      final respFaucet = await acmeAPI.callFaucet(liteAccount);
      print('faucet - ${respFaucet}');

      // 5. Wait at least 4 seconds for a transaction to settle on the network
      final sleep = await Future.delayed(Duration(seconds: 4));
      final resptx = await acmeAPI.callGetTokenTransaction(respFaucet);

      // 6. Credits are converted from ACME token
      //   6.1 Get current timestamp in microseconds it works as Nonce
      int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;

      //   6.2 Execute actual credits call
      final respCredits = await acmeAPI.callAddCredits(liteAccount, 1000, timestamp);
      final sleepC = await Future.delayed(Duration(seconds: 4));
      print('credits - ${respCredits}');

      //   6.3 Check that balance indeed updated
      final respAccount = await acmeAPI.callQuery(liteAccount.address);
      print(respAccount.creditBalance.toString());

      return respAccount.url;
    }

    ///
    ///
    Future<String?> makeAdiTest() async {
      // 1. Generate some random data for private keys
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      // 2. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey = ed.public(privateKey);

      // 3. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.address = currentURL.getPath();
      liteAccount.URL = currentURL;

      //   3.1 Store associated private key data along with Address structure
      //       internal methods will use it to sign payloads
      liteAccount.puk = HEX.encode(publicKey.bytes);
      liteAccount.pik = privateKey.bytes;
      liteAccount.pikHex = HEX.encode(privateKey.bytes);

      print(liteAccount.address);

      // 4. Initialize API class
      final acmeAPI = ACMEApiV2("http://178.20.158.25:56660/", "v2");

      // 5. Add ACME tokens from faucet, at least 3 times because fee is high
      //      - must maintain 4s delay for tx to settle, otherwise it may stall account chain
      final respFaucet = await acmeAPI.callFaucet(liteAccount);
      final sleep = await Future.delayed(Duration(seconds: 4));
      final respFaucet2 = await acmeAPI.callFaucet(liteAccount);
      final sleep2 = await Future.delayed(Duration(seconds: 4));
      final respFaucet3 = await acmeAPI.callFaucet(liteAccount);
      final sleep3 = await Future.delayed(Duration(seconds: 4));
      print('Faucets - ${respFaucet}');

      final respAccountL = await acmeAPI.callQuery(liteAccount.address);
      print(
          'Lite Account ${respAccountL.url}:\n ACME - ${respAccountL.balance}, Credits - ${respAccountL.creditBalance}');

      // 6. Credits are converted from ACME token
      //   6.1 Get current timestamp in microseconds it works as Nonce
      int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;

      //   6.2 Execute actual credits call
      //       ADI very expensive, needs 5000 credits
      final respCredits = await acmeAPI.callAddCredits(liteAccount, 3000 * 100, timestamp);
      final sleep6 = await Future.delayed(Duration(seconds: 4));
      print('Faucets - ${respCredits}');

      // Collect info about Balances
      final respAccountL2 = await acmeAPI.callQuery(liteAccount.address);
      print(
          'Lite Account ${respAccountL2.url}:\n ACME - ${respAccountL2.balance}, Credits - ${respAccountL2.creditBalance}');

      // we need more credits
      final respFaucet4 = await acmeAPI.callFaucet(liteAccount);
      final sleep4 = await Future.delayed(Duration(seconds: 4));
      final respFaucet5 = await acmeAPI.callFaucet(liteAccount);
      final sleep5 = await Future.delayed(Duration(seconds: 4));

      timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final respCredits2 = await acmeAPI.callAddCredits(liteAccount, 2000 * 100, timestamp);
      final sleep62 = await Future.delayed(Duration(seconds: 4));

      // Collect info about Balances
      final respAccountL3 = await acmeAPI.callQuery(liteAccount.address);
      print(
          'Lite Account ${respAccountL3.url}:\n ACME - ${respAccountL3.balance}, Credits - ${respAccountL3.creditBalance}');

      // 6. Generate ADI
      // 6.1 Every ADI is unique, in order to avoid name clash, create random number
      //var rng = new Random();
      //var num = new List.generate(12, (_) => rng.nextInt(100)).reduce((value, element) => value + element);

      // OR use timestamp

      // 7. Add timestamp
      //    Every tx should maintain unique Nonce, thus calling it again
      //    otherwise tx will fail
      int timestampForAdi = DateTime.now().toUtc().millisecondsSinceEpoch;

      // 6.2 Prepare ADI structure that we'll forward to API
      //    - here we reuse keys from lite account but new can be created and supplied
      //    - sponsor defines who will pay the creation fee
      IdentityADI newADI = IdentityADI("", "acc://cosmonaut-" + timestampForAdi.toString(), "");
      newADI
        ..sponsor = liteAccount.address
        ..puk = liteAccount.puk
        ..pik = liteAccount.pik
        ..countKeybooks = 1
        ..countAccounts = 0;

      print('ADI - ${newADI.path}');

      // 8. Execute specific API method and provide arguments
      String? txhash = "";
      try {
        final resp = await acmeAPI.callCreateAdi(liteAccount, newADI, timestampForAdi, "book0", "page0");
        txhash = resp;
      } catch (e) {
        e.toString();
        print(e.toString());
        return "";
      }
      final sleep7 = await Future.delayed(Duration(seconds: 10));

      // 9. Check created ADI
      final respAccountAdi = await acmeAPI.callQuery(newADI.path);
      print('ADI: ${respAccountAdi.url}');

      return txhash;
    }

    ///
    ///
    Future<String?> makeTokenAccountTest() async {
      // 1. Generate some random data for private keys
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      // 2. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey = ed.public(privateKey);

      // 3. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.address = currentURL.getPath();
      liteAccount.URL = currentURL;

      //   3.1 Store associated private key data along with Address structure
      //       internal methods will use it to sign payloads
      liteAccount.puk = HEX.encode(publicKey.bytes);
      liteAccount.pik = privateKey.bytes;
      liteAccount.pikHex = HEX.encode(privateKey.bytes);

      print(liteAccount.address);

      // 4. Initialize API class
      final acmeAPI = ACMEApiV2("http://178.20.158.25:56660/", "v2");

      // 5. Add ACME tokens from faucet, at least 3 times because fee is high
      //      - must maintain 4s delay for tx to settle, otherwise it may stall account chain
      final respFaucet = await acmeAPI.callFaucet(liteAccount);
      final sleep = await Future.delayed(Duration(seconds: 4));
      final respFaucet2 = await acmeAPI.callFaucet(liteAccount);
      final sleep2 = await Future.delayed(Duration(seconds: 4));
      final respFaucet3 = await acmeAPI.callFaucet(liteAccount);
      final sleep3 = await Future.delayed(Duration(seconds: 4));
      print('Faucets - ${respFaucet}');

      final respAccountL = await acmeAPI.callQuery(liteAccount.address);
      print(
          'Lite Account ${respAccountL.url}:\n ACME - ${respAccountL.balance}, Credits - ${respAccountL.creditBalance}');

      // 6. Credits are converted from ACME token
      //   6.1 Get current timestamp in microseconds it works as Nonce
      int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;

      //   6.2 Execute actual credits call
      //       ADI very expensive, needs 5000 credits
      final respCredits = await acmeAPI.callAddCredits(liteAccount, 3000 * 100, timestamp);
      final sleep6 = await Future.delayed(Duration(seconds: 4));
      print('Faucets - ${respCredits}');

      // Collect info about Balances
      final respAccountL2 = await acmeAPI.callQuery(liteAccount.address);
      print(
          'Lite Account ${respAccountL2.url}:\n ACME - ${respAccountL2.balance}, Credits - ${respAccountL2.creditBalance}');

      // we need more credits
      final respFaucet4 = await acmeAPI.callFaucet(liteAccount);
      final sleep4 = await Future.delayed(Duration(seconds: 4));
      final respFaucet5 = await acmeAPI.callFaucet(liteAccount);
      final sleep5 = await Future.delayed(Duration(seconds: 4));

      timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final respCredits2 = await acmeAPI.callAddCredits(liteAccount, 2000 * 100, timestamp);
      final sleep62 = await Future.delayed(Duration(seconds: 4));

      // Collect info about Balances
      final respAccountL3 = await acmeAPI.callQuery(liteAccount.address);
      print(
          'Lite Account ${respAccountL3.url}:\n ACME - ${respAccountL3.balance}, Credits - ${respAccountL3.creditBalance}');

      // 6. Generate ADI
      // 6.1 Every ADI is unique, in order to avoid name clash, create random number
      //var rng = new Random();
      //var num = new List.generate(12, (_) => rng.nextInt(100)).reduce((value, element) => value + element);

      // OR use timestamp

      // 7. Add timestamp
      //    Every tx should maintain unique Nonce, thus calling it again
      //    otherwise tx will fail
      int timestampForAdi = DateTime.now().toUtc().millisecondsSinceEpoch;

      // 6.2 Prepare ADI structure that we'll forward to API
      //    - here we reuse keys from lite account but new can be created and supplied
      //    - sponsor defines who will pay the creation fee
      IdentityADI newADI = IdentityADI("", "acc://cosmonaut-" + timestampForAdi.toString(), "");
      newADI
        ..sponsor = liteAccount.address
        ..puk = liteAccount.puk
        ..pik = liteAccount.pik
        ..countKeybooks = 1
        ..countAccounts = 0;

      print('ADI - ${newADI.path}');

      // 8. Execute specific API method and provide arguments
      String? txhash = "";
      try {
        final resp = await acmeAPI.callCreateAdi(liteAccount, newADI, timestampForAdi, "book0", "page0");
        txhash = resp;
      } catch (e) {
        e.toString();
        print(e.toString());
        return "";
      }
      final sleep7 = await Future.delayed(Duration(seconds: 10));

      // 9. Check created ADI
      final respAccountAdi = await acmeAPI.callQuery(newADI.path);
      print('ADI: ${respAccountAdi.url}');

      return txhash;
    }

    ///
    ///
    Future<String?> makeDataAccountTest() async {
      // 1. Generate some random data for private keys
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      // 2. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey = ed.public(privateKey);

      // 3. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.address = currentURL.getPath();
      liteAccount.URL = currentURL;

      //   3.1 Store associated private key data along with Address structure
      //       internal methods will use it to sign payloads
      liteAccount.puk = HEX.encode(publicKey.bytes);
      liteAccount.pik = privateKey.bytes;
      liteAccount.pikHex = HEX.encode(privateKey.bytes);

      print(liteAccount.address);

      // 4. Initialize API class
      final acmeAPI = ACMEApiV2("http://178.20.158.25:56660/", "v2");

      // 5. Add ACME tokens from faucet, at least 3 times because fee is high
      //      - must maintain 4s delay for tx to settle, otherwise it may stall account chain
      final respFaucet = await acmeAPI.callFaucet(liteAccount);
      final sleep = await Future.delayed(Duration(seconds: 4));
      final respFaucet2 = await acmeAPI.callFaucet(liteAccount);
      final sleep2 = await Future.delayed(Duration(seconds: 4));
      final respFaucet3 = await acmeAPI.callFaucet(liteAccount);
      final sleep3 = await Future.delayed(Duration(seconds: 4));
      print('Faucets - ${respFaucet}');

      final respAccountL = await acmeAPI.callQuery(liteAccount.address);
      print(
          'Lite Account ${respAccountL.url}:\n ACME - ${respAccountL.balance}, Credits - ${respAccountL.creditBalance}');

      // 6. Credits are converted from ACME token
      //   6.1 Get current timestamp in microseconds it works as Nonce
      int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;

      //   6.2 Execute actual credits call
      //       ADI very expensive, needs 5000 credits
      final respCredits = await acmeAPI.callAddCredits(liteAccount, 3000 * 100, timestamp);
      final sleepC = await Future.delayed(Duration(seconds: 4));
      print('Faucets - ${respCredits}');

      // Collect info about Balances
      final respAccountL2 = await acmeAPI.callQuery(liteAccount.address);
      print(
          'Lite Account ${respAccountL2.url}:\n ACME - ${respAccountL2.balance}, Credits - ${respAccountL2.creditBalance}');

      // we need more credits
      final respFaucet4 = await acmeAPI.callFaucet(liteAccount);
      final sleep4 = await Future.delayed(Duration(seconds: 4));
      final respFaucet5 = await acmeAPI.callFaucet(liteAccount);
      final sleep5 = await Future.delayed(Duration(seconds: 4));

      timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final respCredits2 = await acmeAPI.callAddCredits(liteAccount, 2000 * 100, timestamp);
      final sleepC2 = await Future.delayed(Duration(seconds: 4));

      // Collect info about Balances
      final respAccountL3 = await acmeAPI.callQuery(liteAccount.address);
      print(
          'Lite Account ${respAccountL3.url}:\n ACME - ${respAccountL3.balance}, Credits - ${respAccountL3.creditBalance}');

      // 6. Generate ADI
      // 6.1 Every ADI is unique, in order to avoid name clash, create random number
      //var rng = new Random();
      //var num = new List.generate(12, (_) => rng.nextInt(100)).reduce((value, element) => value + element);

      // OR use timestamp

      // 7. Add timestamp
      //    Every tx should maintain unique Nonce, thus calling it again
      //    otherwise tx will fail
      int timestampForAdi = DateTime.now().toUtc().millisecondsSinceEpoch;

      // 6.2 Prepare ADI structure that we'll forward to API
      //    - here we reuse keys from lite account but new can be created and supplied
      //    - sponsor defines who will pay the creation fee
      IdentityADI newADI = IdentityADI("", "acc://cosmonaut-" + timestampForAdi.toString(), "");
      newADI
        ..sponsor = liteAccount.address
        ..puk = liteAccount.puk
        ..pik = liteAccount.pik
        ..pikHex = liteAccount.pikHex
        ..countKeybooks = 1
        ..countAccounts = 0;

      print('ADI - ${newADI.path}');

      String? txhash = "";
      try {
        final resp = await acmeAPI.callCreateAdi(liteAccount, newADI, timestampForAdi, "book0", "page0");
        txhash = resp;
      } catch (e) {
        e.toString();
        print(e.toString());
        return "";
      }
      final sleep7 = await Future.delayed(Duration(seconds: 4));

      // 9. Check created ADI
      final respAccountAdi = await acmeAPI.callQuery(newADI.path);
      print('ADI: ${respAccountAdi.url}');

      // we need more credits BUT this time for ADI keypage
      final respFaucet6 = await acmeAPI.callFaucet(liteAccount);
      final sleep6 = await Future.delayed(Duration(seconds: 4));
      final respFaucet7 = await acmeAPI.callFaucet(liteAccount);
      final sleep8 = await Future.delayed(Duration(seconds: 4));
      final respFaucet8 = await acmeAPI.callFaucet(liteAccount);
      final sleep9 = await Future.delayed(Duration(seconds: 4));

      timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      KeyPage defKeypage = KeyPage(newADI.path! + "/book0", newADI.path! + "/page0", "");
      final respCredits3 = await acmeAPI.callAddCredits(liteAccount, 2500 * 100, timestamp, defKeypage);
      final sleepC3 = await Future.delayed(Duration(seconds: 4));

      // Collect info about Balances
      final respAccountL4 = await acmeAPI.callQuery(defKeypage.path);
      print('Key Page ${respAccountL4.url}:\n Credits - ${respAccountL4.creditBalance}');

      print("Check for nonce");
      int keyPageHeight = 1;
      final kbData = await acmeAPI.callQuery(newADI.path! + "/page0");
      kbData.hashCode;
      if (kbData != null) {
        keyPageHeight = kbData.nonce!;
      }

      // 8. Execute specific API method and provide arguments
      int timestampForAdiTokenAccount = DateTime.now().toUtc().millisecondsSinceEpoch;
      txhash = "";
      String? tknName = "tkna-" + timestampForAdiTokenAccount.toString();
      try {
        final resp = await acmeAPI.callCreateTokenAccount(liteAccount, newADI, tknName, newADI.path! + "/book0",
            timestampForAdiTokenAccount, newADI.puk, newADI.pikHex, keyPageHeight); // is scratch or not
        txhash = resp;
      } catch (e) {
        e.toString();
        print(e.toString());
        return "";
      }
      final sleep10 = await Future.delayed(Duration(seconds: 10));

      final respTokenAccount = await acmeAPI.callQuery(newADI.path! + "/" + tknName);
      print('ADI Token Account: ${respTokenAccount.url}');

      // we need more credits
      final respFaucet10 = await acmeAPI.callFaucet(liteAccount);
      final sleep11 = await Future.delayed(Duration(seconds: 4));
      final respFaucet11 = await acmeAPI.callFaucet(liteAccount);
      final sleep12 = await Future.delayed(Duration(seconds: 4));
      final respFaucet12 = await acmeAPI.callFaucet(liteAccount);
      final sleep13 = await Future.delayed(Duration(seconds: 4));

      timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      //KeyPage defKeypage = KeyPage(newADI.path! + "/book0", newADI.path! + "/page0", "");
      final respCredits4 = await acmeAPI.callAddCredits(liteAccount, 3000 * 100, timestamp, defKeypage);
      final sleepC4 = await Future.delayed(Duration(seconds: 4));

      final kbData2 = await acmeAPI.callQuery(defKeypage.path);
      print('Key Page ${kbData2.url}:\n Credits - ${kbData2.creditBalance}');
      kbData2.hashCode;
      if (kbData2 != null) {
        keyPageHeight = kbData2.nonce!;
      }

      // 8. Execute specific API method and provide arguments
      txhash = "";
      int timestampForDataAccount = DateTime.now().toUtc().millisecondsSinceEpoch;
      String? dtknName = "data-tkna-" + timestampForDataAccount.toString();
      try {
        final resp = await acmeAPI.callCreateDataAccount(liteAccount, newADI, dtknName, timestampForDataAccount,
            newADI.path! + "/book0", false, keyPageHeight);
        txhash = resp;
      } catch (e) {
        e.toString();
        print(e.toString());
        return "";
      }
      final sleep14 = await Future.delayed(Duration(seconds: 12));

      // 11. Check created Data Account
      final respDataAccount = await acmeAPI.callQuery(newADI.path! + "/" + dtknName);
      print('ADI Data Account: ${respDataAccount.url}');

      // 12. Write Data to Data Account

      return txhash;
    }

    /// Test Token related functionality
    ///   - Create New Custom Token
    ///   - Issue Tokens
    ///   - Burn Tokens
    Future<String> makeCustomTokensTest() async {
      return "";
    }

    test('Tests', () async {
      final String? respFaucet = await makeFaucetTest();
      expect(respFaucet?.isNotEmpty, isTrue);

      final String? respTransaction = await makeTransactionsTest();
      expect(respTransaction?.isNotEmpty, isTrue);

      // final String respC = await makeCreditsTest();
      // expect(respC.isNotEmpty, isTrue);

      // final String? respA = await (makeAdiTest());
      // expect(respA?.isNotEmpty, isTrue);

      //final String? respA = await (makeDataAccountTest());
      //expect(respA?.isNotEmpty, isTrue);

      //final String? respA = await (makeCustomTokensTest());
      //expect(respA?.isNotEmpty, isTrue);
    });

    test('Faucet Test - Multiple Calls Over Short Period', () async {
      // final String resp = await makeFaucetTest();
      // for (int i = 0; i < 10; i++) {
      //   final String resp = await makeFaucetTest();
      //   final sleep = await Future.delayed(Duration(seconds: 1));
      // }
      // expect(resp.isNotEmpty, isTrue);
    });

    //exit(0);
  }, timeout: Timeout(Duration(minutes: 8)));
}
