import 'dart:typed_data';
import 'dart:math';
import 'package:hex/hex.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/keccak.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/ecc/api.dart';

class TronApiService {

  static final ECCurve_secp256k1 secp256k1 = ECCurve_secp256k1();

  Future<Map<String, dynamic>?> getAddressFromPrivateKey(String privateKey) async {
    try {
      final privateKeyBytes = HEX.decode(privateKey);
      final publicKey = _generatePublicKey(privateKeyBytes);
      final address = _generateTronAddress(publicKey);
      
      return {
        'privateKey': privateKey,
        'address': address,
      };
    } catch (e) {
      print('Error getting address from private key: $e');
      return null;
    }
  }

  Uint8List _generatePublicKey(List<int> privateKeyBytes) {
    final privateKey = ECPrivateKey(
      BigInt.parse(HEX.encode(privateKeyBytes), radix: 16),
      secp256k1,
    );
    
    final publicKey = secp256k1.G * privateKey.d;
    final publicKeyBytes = publicKey!.getEncoded(false);
    
    return Uint8List.fromList(publicKeyBytes.sublist(1)); // Remove prefix byte
  }

  String _generateTronAddress(Uint8List publicKey) {
    // Keccak-256 hash of public key
    final keccak = KeccakDigest(256);
    final keccakHash = keccak.process(publicKey);
    
    // Take last 20 bytes
    final address = keccakHash.sublist(12);
    
    // Add Tron prefix (0x41)
    final prefixedAddress = [0x41, ...address];
    
    // Double SHA256
    final firstSha = sha256.convert(prefixedAddress);
    final secondSha = sha256.convert(firstSha.bytes);
    
    // Take first 4 bytes as checksum
    final checksum = secondSha.bytes.sublist(0, 4);
    
    // Final address = prefix + address + checksum
    final finalAddress = [...prefixedAddress, ...checksum];
    
    // Encode to base58
    return _base58Encode(finalAddress);
  }

  String _base58Encode(List<int> bytes) {
    const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    var num = BigInt.parse(HEX.encode(bytes), radix: 16);
    var base = BigInt.from(58);
    var result = '';
    
    while (num > BigInt.zero) {
      var remainder = num.remainder(base);
      num = num ~/ base;
      result = alphabet[remainder.toInt()] + result;
    }
    
    // Add leading zeros
    for (var byte in bytes) {
      if (byte == 0) {
        result = '1' + result;
      } else {
        break;
      }
    }
    
    return result;
  }

  Future<Map<String, dynamic>> createAccount() async {
    try {
      final privateKey = _generatePrivateKey();
      final response = await getAddressFromPrivateKey(privateKey);
      
      if (response == null) {
        throw Exception('Failed to generate address');
      }
      
      return response;
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  String _generatePrivateKey() {
    final random = Random.secure();
    final privateKeyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return HEX.encode(privateKeyBytes);
  }

  Future<Map<String, dynamic>> importFromPrivateKey(String privateKey) async {
    final response = await getAddressFromPrivateKey(privateKey);
    if (response == null) {
      throw Exception('Failed to import from private key');
    }
    return response;
  }
} 