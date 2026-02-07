import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart' as web3;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/keccak.dart';

class TronTransactionService {
  // 网络配置
  static const String mainnetNode = 'https://api.trongrid.io';
  static const String shastaTestnetNode = 'https://api.shasta.trongrid.io';
  
  // 常用TRC20合约地址
  static const String usdtMainnet = 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t';
  static const String usdtTestnet = 'TXLAQ63Xg1NAzckPwKHvzw7CSEmLMEqcdj';

  final String privateKey;
  final String nodeUrl;
  
  TronTransactionService({
    required this.privateKey, 
    bool isTestnet = true
  }) : nodeUrl = isTestnet ? shastaTestnetNode : mainnetNode;
  
  // 获取当前地址
  String get address => _privateKeyToAddress(privateKey);
  
  // ================ TRX 转账 ================
  
  /// 发送TRX
  Future<String> sendTRX(String toAddress, int amount) async {
    try {
      // 1. 创建交易
      final transaction = await _createTransaction(toAddress, amount);
      if (transaction == null) {
        throw Exception('创建交易失败: 返回数据为空');
      }
      
      // 2. 本地签名交易
      final signedTx = await _signTransactionLocally(transaction);
      if (signedTx == null) {
        throw Exception('签名交易失败: 签名数据为空');
      }
      
      // 3. 广播交易
      final txId = await _broadcastTransaction(signedTx);
      if (txId == null || txId.isEmpty) {
        throw Exception('广播交易失败: 交易ID为空');
      }
      
      return txId;
    } catch (e) {
      throw Exception('TRX转账错误: $e');
    }
  }
  
  // ================ TRC20 转账 ================
  
  Future<String> sendTRC20(
    String contractAddress,
    String toAddress,
    BigInt amount, {
    int feeLimit = 10000000
  }) async {
    try {
      // 1. 创建智能合约调用交易
      final transaction = await _createTRC20Transaction(
        contractAddress,
        toAddress,
        amount,
        feeLimit: feeLimit
      );
      
      // 2. 本地签名交易
      final signedTx = await _signTransactionLocally(transaction);
      
      // 3. 广播交易
      return await _broadcastTransaction(signedTx);
    } catch (e) {
      throw Exception('TRC20转账错误: $e');
    }
  }
  
  // ================ 核心方法 ================
  
  Future<Map<String, dynamic>> _createTransaction(String toAddress, int amount) async {
    // 获取当前时间戳（毫秒）
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiration = now + 60000; // 当前时间加1分钟
    
    final requestBody = {
      'owner_address': address,
      'to_address': toAddress,
      'amount': amount,
      'visible': true,
      'timestamp': now,
      'expiration': expiration
    };
    
    print('创建交易请求:');
    print('URL: $nodeUrl/wallet/createtransaction');
    print('请求数据: ${json.encode(requestBody)}');
    
    final response = await http.post(
      Uri.parse('$nodeUrl/wallet/createtransaction'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );
    
    print('创建交易响应:');
    print('状态码: ${response.statusCode}');
    print('响应数据: ${response.body}');
    
    if (response.statusCode != 200) {
      throw Exception('创建交易失败: ${response.body}');
    }
    
    final result = json.decode(response.body);
    if (result == null) {
      throw Exception('创建交易失败: 返回数据为空');
    }
    
    // 验证必要字段
    if (result['txID'] == null) {
      throw Exception('创建交易失败: 缺少交易ID');
    }
    
    if (result['raw_data'] == null) {
      throw Exception('创建交易失败: 缺少交易数据');
    }
    
    return result;
  }
  
  Future<Map<String, dynamic>> _createTRC20Transaction(
    String contractAddress,
    String toAddress,
    BigInt amount, {
    required int feeLimit
  }) async {
    const transferMethodSignature = 'transfer(address,uint256)';
    final toAddressHex = toAddress.replaceFirst('41', '0x');
    final params = AbiUtil.encodeParams(
      ['address', 'uint256'],
      [toAddressHex, amount]
    );
    
    final response = await http.post(
      Uri.parse('$nodeUrl/wallet/triggersmartcontract'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contract_address': contractAddress,
        'function_selector': transferMethodSignature,
        'parameter': params,
        'owner_address': address,
        'fee_limit': feeLimit,
        'call_value': 0,
        'visible': true
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('创建TRC20交易失败: ${response.body}');
    }
    
    final result = json.decode(response.body);
    return result['transaction'];
  }
  
  Future<Map<String, dynamic>> _signTransactionLocally(Map<String, dynamic> transaction) async {
    if (transaction == null) {
      throw Exception('签名交易失败: 交易数据为空');
    }
    
    final transactionRawData = transaction['raw_data_hex'];
    if (transactionRawData == null) {
      throw Exception('签名交易失败: 缺少raw_data_hex字段');
    }
    
    try {
      final privateKeyBytes = HEX.decode(privateKey);
      final transactionRawDataBytes = HEX.decode(transactionRawData);
      final signature = await _signData(
        Uint8List.fromList(transactionRawDataBytes),
        privateKey
      );
      
      return {
        ...transaction,
        'signature': [signature],
      };
    } catch (e) {
      throw Exception('签名交易失败: $e');
    }
  }
  
  Future<String> _broadcastTransaction(Map<String, dynamic> signedTx) async {
    print('广播交易请求:');
    print('URL: $nodeUrl/wallet/broadcasttransaction');
    print('请求数据: ${json.encode(signedTx)}');
    
    final response = await http.post(
      Uri.parse('$nodeUrl/wallet/broadcasttransaction'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(signedTx),
    );
    
    print('广播交易响应:');
    print('状态码: ${response.statusCode}');
    print('响应数据: ${response.body}');
    
    if (response.statusCode != 200) {
      throw Exception('广播交易失败: ${response.body}');
    }
    
    final result = json.decode(response.body);
    if (result['result'] != true) {
      throw Exception('交易失败: ${result['code']} - ${result['message']}');
    }
    
    final txId = result['txid'];
    if (txId == null) {
      throw Exception('交易ID为空，请检查交易参数');
    }
    
    return txId;
  }
  
  // ================ 签名相关方法 ================
  
  Future<String> _signData(Uint8List data, String privateKey) async {
    try {
      // 使用 PointyCastle 的 ECDSA 签名
      final curve = ECCurve_secp256k1();
      final privateKeyBigInt = BigInt.parse(privateKey, radix: 16);
      final privateKeyParam = ECPrivateKey(privateKeyBigInt, curve);
      
      // 创建签名器
      final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64));
      signer.init(true, PrivateKeyParameter<ECPrivateKey>(privateKeyParam));
      
      // 签名数据
      final signature = signer.generateSignature(data) as ECSignature;
      
      // 转换为字节
      final rBytes = _bigIntToBytes(signature.r, 32);
      final sBytes = _bigIntToBytes(signature.s, 32);
      
      // 在 Tron 中，v 值固定为 27
      final recoveryParam = 27;
      
      // 打印调试信息
      print('签名数据:');
      print('私钥: $privateKey');
      print('r: ${signature.r.toRadixString(16)}');
      print('s: ${signature.s.toRadixString(16)}');
      print('恢复参数: $recoveryParam');
      
      // 返回 65 字节签名
      return HEX.encode(Uint8List.fromList([...rBytes, ...sBytes, recoveryParam]));
    } catch (e) {
      print('签名错误: $e');
      rethrow;
    }
  }
  
  Uint8List _bigIntToBytes(BigInt number, int length) {
    var hex = number.toRadixString(16).padLeft(length * 2, '0');
    if (hex.length > length * 2) {
      hex = hex.substring(hex.length - length * 2);
    }
    return Uint8List.fromList(HEX.decode(hex));
  }
  
  // ================ 地址相关方法 ================
  
  String _privateKeyToAddress(String privateKey) {
    final privateKeyBytes = HEX.decode(privateKey);
    final publicKey = _generatePublicKey(privateKeyBytes);
    final address = _generateTronAddress(publicKey);
    return address;
  }
  
  Uint8List _generatePublicKey(List<int> privateKeyBytes) {
    final curve = ECCurve_secp256k1();
    final privateKey = ECPrivateKey(
      BigInt.parse(HEX.encode(privateKeyBytes), radix: 16),
      curve,
    );
    
    final publicKey = curve.G * privateKey.d;
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
}

class AbiUtil {
  static String encodeParams(List<String> types, List<dynamic> values) {
    if (types.length != values.length) {
      throw ArgumentError('Types and values length mismatch');
    }
    
    if (types[0] == 'address' && types[1] == 'uint256') {
      final address = values[0] as String;
      final amount = values[1] as BigInt;
      
      final cleanAddress = address.replaceFirst('0x', '');
      if (cleanAddress.length != 40) {
        throw ArgumentError('Invalid address length');
      }
      
      final addressBytes = HEX.decode(cleanAddress.padLeft(64, '0'));
      final amountBytes = _intToBytes(amount, 32);
      
      final result = [...addressBytes, ...amountBytes];
      return HEX.encode(result);
    }
    
    throw UnimplementedError('Only transfer(address,uint256) is implemented');
  }
  
  static List<int> _intToBytes(BigInt number, int length) {
    var hexStr = number.toRadixString(16).padLeft(length * 2, '0');
    return HEX.decode(hexStr);
  }
} 