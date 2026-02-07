import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'wallet_generator_service.dart';

class WalletService {
  final DatabaseService _dbService = DatabaseService();
  final WalletGeneratorService _generatorService = WalletGeneratorService();

  // TODO: Implement actual wallet storage
  Future<bool> hasWallet() async {
    final db = await _dbService.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM wallets'),
    );
    return count != null && count > 0;
  }

  Future<bool> verifyPassword(String password, String address) async {
    try {
      print('Verifying password for address: $address');
      final db = await _dbService.database;
      final result = await db.query(
        'wallets',
        where: 'address = ? AND password_hash = ?',
        whereArgs: [address, _hashPassword(password)],
      );
      final isValid = result.isNotEmpty;
      print('Password verification result: $isValid');
      return isValid;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  Future<void> deleteWallet(String address) async {
    final db = await _dbService.database;
    await db.delete(
      'wallets',
      where: 'address = ?',
      whereArgs: [address],
    );
  }

  Future<String> getMnemonic(String address) async {
    try {
      print('Fetching mnemonic for address: $address');
      final db = await _dbService.database;
      
      // First check if the wallet exists
      final walletExists = await db.query(
        'wallets',
        columns: ['id'],
        where: 'address = ?',
        whereArgs: [address],
      );
      
      if (walletExists.isEmpty) {
        print('No wallet found for address: $address');
        throw Exception('钱包未找到，请确保钱包已正确创建');
      }

      final result = await db.query(
        'wallets',
        columns: ['mnemonic'],
        where: 'address = ?',
        whereArgs: [address],
      );
      
      if (result.isEmpty) {
        print('No mnemonic found for address: $address');
        throw Exception('助记词未找到，请联系客服');
      }
      
      final mnemonic = result.first['mnemonic'] as String;
      if (mnemonic.isEmpty) {
        print('Empty mnemonic found for address: $address');
        throw Exception('助记词为空，请联系客服');
      }
      
      print('Successfully retrieved mnemonic for address: $address');
      return mnemonic;
    } catch (e) {
      print('Error getting mnemonic: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('获取助记词失败，请稍后重试');
    }
  }

  String _hashPassword(String password) {
    // TODO: Implement proper password hashing
    return password; // 临时实现，实际应该使用安全的哈希算法
  }

  Future<WalletData> getCurrentWallet() async {
    try {
      print('Getting current wallet...');
      final db = await _dbService.database;
      
      // First try to get the current wallet
      print('Querying wallet with is_current = 1');
      final List<Map<String, dynamic>> currentWallets = await db.query(
        'wallets',
        where: 'is_current = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (currentWallets.isNotEmpty) {
        print('Found current wallet');
        final wallet = currentWallets.first;
        return WalletData(
          mnemonic: wallet['mnemonic'] as String,
          privateKey: wallet['private_key'] as String,
          address: wallet['address'] as String,
          name: wallet['name'] as String,
          isBackedUp: wallet['is_backed_up'] == 1,
        );
      }

      // If no current wallet, get the first wallet
      print('No current wallet found, getting first wallet');
      final List<Map<String, dynamic>> allWallets = await db.query(
        'wallets',
        limit: 1,
      );

      if (allWallets.isEmpty) {
        print('No wallets found in database');
        throw Exception('No wallet found');
      }

      // Set the first wallet as current
      final wallet = allWallets.first;
      print('Setting first wallet as current: ${wallet['address']}');
      
      await db.update(
        'wallets',
        {'is_current': 1},
        where: 'address = ?',
        whereArgs: [wallet['address']],
      );

      return WalletData(
        mnemonic: wallet['mnemonic'] as String,
        privateKey: wallet['private_key'] as String,
        address: wallet['address'] as String,
        name: wallet['name'] as String,
        isBackedUp: wallet['is_backed_up'] == 1,
      );
    } catch (e) {
      print('Error getting current wallet: $e');
      rethrow;
    }
  }
} 