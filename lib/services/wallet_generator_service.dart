import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/ec_key_generator.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:bip32/bip32.dart' as bip32;
import 'tron_api_service.dart';

class WalletData {
  final String mnemonic;
  final String privateKey;
  final String address;
  final String name;
  final bool isBackedUp;

  WalletData({
    required this.mnemonic,
    required this.privateKey,
    required this.address,
    this.name = '',  // 默认为空字符串
    this.isBackedUp = false,
  });
}

class WalletGeneratorService {
  final TronApiService _tronApi = TronApiService();
  static const int TRON_COIN = 195;  // SLIP-0044
  static const int CHANGE_EXTERNAL = 0;
  static const int ADDRESS_INDEX = 0;

  Future<WalletData> generateWallet() async {
    try {
      // Generate mnemonic (12 words is standard)
      final mnemonic = bip39.generateMnemonic();
      
      // Generate wallet from mnemonic
      return await _generateFromMnemonic(mnemonic);
    } catch (e) {
      print('Error generating wallet: $e');
      rethrow;
    }
  }

  Future<WalletData> importWalletFromMnemonic(String mnemonic) async {
    try {
      return await importFromMnemonic(mnemonic);
    } catch (e) {
      print('Error importing from mnemonic: $e');
      throw Exception('无效的助记词');
    }
  }

  Future<WalletData> importWalletFromPrivateKey(String privateKey) async {
    try {
      return await importFromPrivateKey(privateKey);
    } catch (e) {
      print('Error importing from private key: $e');
      throw Exception('无效的私钥');
    }
  }

  Future<WalletData> importFromMnemonic(String mnemonic) async {
    try {
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic');
      }
      
      // Generate wallet from mnemonic
      return await _generateFromMnemonic(mnemonic);
    } catch (e) {
      print('Error importing from mnemonic: $e');
      rethrow;
    }
  }

  Future<WalletData> importFromPrivateKey(String privateKey) async {
    try {
      if (!_isValidPrivateKey(privateKey)) {
        throw Exception('Invalid private key');
      }

      final address = await _generateAddressFromPrivateKey(privateKey);
      
      return WalletData(
        mnemonic: '', // No mnemonic for private key import
        privateKey: privateKey,
        address: address,
      );
    } catch (e) {
      print('Error importing from private key: $e');
      rethrow;
    }
  }

  Future<WalletData> _generateFromMnemonic(String mnemonic) async {
    try {
      print('Generating wallet from mnemonic...');
      // Convert mnemonic to seed
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // Create master node
      final node = bip32.BIP32.fromSeed(seed);
      
      // Derive child node (m/44'/195'/0'/0/0)
      final child = node
          .derivePath("m/44'/${TRON_COIN}'/0'/${CHANGE_EXTERNAL}/${ADDRESS_INDEX}");
      
      // Get private key
      final privateKey = HEX.encode(child.privateKey!);
      
      // Generate address from private key
      final address = await _generateAddressFromPrivateKey(privateKey);
      print('Generated address: $address');
      
      return WalletData(
        mnemonic: mnemonic,
        privateKey: privateKey,
        address: address,
      );
    } catch (e) {
      print('Error generating from mnemonic: $e');
      rethrow;
    }
  }

  Future<String> _generateAddressFromPrivateKey(String privateKey) async {
    try {
      final response = await _tronApi.getAddressFromPrivateKey(privateKey);
      if (response == null || !response.containsKey('address')) {
        throw Exception('Failed to generate address from private key');
      }
      return response['address'];
    } catch (e) {
      print('Error generating address from private key: $e');
      rethrow;
    }
  }

  bool _isValidPrivateKey(String privateKey) {
    try {
      // Check if it's a valid hex string of correct length (64 characters = 32 bytes)
      if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(privateKey)) {
        return false;
      }
      
      // Convert to BigInt and check if it's in valid range
      final pkInt = BigInt.parse(privateKey, radix: 16);
      final curveOrder = ECCurve_secp256k1().n;
      
      return pkInt > BigInt.zero && pkInt < curveOrder;
    } catch (e) {
      return false;
    }
  }
} 