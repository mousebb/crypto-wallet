import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, Directory, File;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'wallet_generator_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static SharedPreferences? _prefs;
  static const String _walletKey = 'wallet_data';
  static const String dbName = 'wallet.db';

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<void> _initSharedPreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String> getDatabasePath() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Get the application documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      String dbPath = join(documentsDirectory.path, dbName);
      print('Database path: $dbPath');
      return dbPath;
    } else {
      // For desktop platforms, use current directory
      String currentDir = Directory.current.path;
      String dbPath = join(currentDir, dbName);
      print('Database path: $dbPath');
      return dbPath;
    }
  }

  Future<void> initializeDatabase() async {
    if (kIsWeb) return;

    try {
      String path = await getDatabasePath();
      print('Checking database at: $path');

      // Initialize database based on platform
      if (Platform.isAndroid) {
        _database = await openDatabase(
          path,
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      } else {
        _database = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          ),
        );
      }
      print('Database initialized successfully');

    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<dynamic> get storage async {
    if (kIsWeb) {
      await _initSharedPreferences();
      return _prefs;
    } else {
      return await database;
    }
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite database is not supported on Web platform');
    }
    if (_database != null) return _database!;
    await initializeDatabase();
    return _database!;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // 添加 is_current 字段
      await db.execute('ALTER TABLE wallets ADD COLUMN is_current INTEGER NOT NULL DEFAULT 0');
      
      // 将第一个钱包设置为当前钱包
      final wallets = await db.query('wallets', limit: 1);
      if (wallets.isNotEmpty) {
        await db.update(
          'wallets',
          {'is_current': 1},
          where: 'address = ?',
          whereArgs: [wallets.first['address']],
        );
      }

      // 创建 settings 表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // 添加 password_hash 字段
      await db.execute('ALTER TABLE wallets ADD COLUMN password_hash TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      print('Creating database tables...');
      await db.execute('''
        CREATE TABLE wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          mnemonic TEXT NOT NULL,
          private_key TEXT NOT NULL,
          password_hash TEXT,
          is_backed_up INTEGER DEFAULT 0,
          is_current INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value INTEGER NOT NULL
        )
      ''');
      print('Database tables created successfully');
    } catch (e) {
      print('Error creating tables: $e');
      rethrow;
    }
  }

  Future<void> saveWallet(WalletData walletData, String password, String name) async {
    if (kIsWeb) {
      final prefs = await storage as SharedPreferences;
      final walletJson = {
        'name': name,
        'mnemonic': walletData.mnemonic,
        'private_key': walletData.privateKey,
        'address': walletData.address,
        'password_hash': _hashPassword(password),
      };
      await prefs.setString(_walletKey, jsonEncode(walletJson));
      print('Wallet saved to SharedPreferences with name: $name');
    } else {
      print('Saving wallet to database...');
      print('Wallet name: $name');
      print('Wallet address: ${walletData.address}');
      print('Password hash: ${_hashPassword(password)}');
      
      final db = await database;
      final data = {
        'name': name,
        'mnemonic': walletData.mnemonic,
        'private_key': walletData.privateKey,
        'address': walletData.address,
        'password_hash': _hashPassword(password),
        'is_backed_up': walletData.isBackedUp ? 1 : 0,
        'is_current': 1,
      };
      
      // First, set all wallets' is_current to 0
      await db.update(
        'wallets',
        {'is_current': 0},
      );
      
      // Then insert the new wallet
      await db.insert(
        'wallets',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Verify the saved data
      final saved = await db.query(
        'wallets',
        where: 'address = ?',
        whereArgs: [walletData.address],
      );
      print('Saved wallet data: $saved');
    }
  }

  String _hashPassword(String password) {
    // TODO: Implement proper password hashing
    final hash = password; // 临时实现，实际应该使用安全的哈希算法
    print('Hashing password: $password -> $hash');
    return hash;
  }

  Future<WalletData?> getWallet() async {
    if (kIsWeb) {
      final prefs = await storage as SharedPreferences;
      final walletJson = prefs.getString(_walletKey);
      if (walletJson == null) return null;
      
      final wallet = jsonDecode(walletJson);
      return WalletData(
        mnemonic: wallet['mnemonic'],
        privateKey: wallet['private_key'],
        address: wallet['address'],
      );
    } else {
      print('Fetching wallet from database...');
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('wallets');
      
      if (maps.isEmpty) {
        print('No wallet found in database');
        return null;
      }
      
      print('Wallet found in database');
      final wallet = maps.first;
      return WalletData(
        mnemonic: wallet['mnemonic'],
        privateKey: wallet['private_key'],
        address: wallet['address'],
      );
    }
  }

  Future<bool> hasWallet() async {
    if (kIsWeb) {
      final prefs = await storage as SharedPreferences;
      return prefs.containsKey(_walletKey);
    } else {
      print('Checking for wallet in database...');
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('wallets');
      final hasWallet = maps.isNotEmpty;
      print('Has wallet: $hasWallet');
      return hasWallet;
    }
  }

  Future<bool> verifyPassword(String address, String password) async {
    print('Verifying password for address: $address');
    print('Input password hash: ${_hashPassword(password)}');
    
    if (kIsWeb) {
      final prefs = await storage as SharedPreferences;
      final walletJson = prefs.getString(_walletKey);
      if (walletJson != null) {
        final wallet = jsonDecode(walletJson);
        final isValid = wallet['address'] == address && 
                       wallet['password_hash'] == _hashPassword(password);
        print('Web storage password verification result: $isValid');
        return isValid;
      }
      return false;
    } else {
      final db = await database;
      final result = await db.query(
        'wallets',
        where: 'address = ? AND password_hash = ?',
        whereArgs: [address, _hashPassword(password)],
      );
      print('Database password verification result: ${result.isNotEmpty}');
      return result.isNotEmpty;
    }
  }

  Future<void> deleteWallet(String address) async {
    print('Deleting wallet with address: $address');
    if (kIsWeb) {
      final prefs = await storage as SharedPreferences;
      await prefs.remove(_walletKey);
      print('Wallet removed from web storage');
    } else {
      final db = await database;
      final result = await db.delete(
        'wallets',
        where: 'address = ?',
        whereArgs: [address],
      );
      print('Deleted $result wallet(s) from database');
    }
  }

  Future<bool> hasWallets() async {
    if (kIsWeb) {
      final prefs = await storage as SharedPreferences;
      final walletJson = prefs.getString(_walletKey);
      return walletJson != null;
    } else {
      final db = await database;
      final result = await db.query('wallets');
      return result.isNotEmpty;
    }
  }

  Future<void> updateBackupStatus(String address, bool isBackedUp) async {
    final db = await database;
    await db.update(
      'wallets',
      {'is_backed_up': isBackedUp ? 1 : 0},
      where: 'address = ?',
      whereArgs: [address],
    );
  }

  Future<void> updateWalletBackupStatus(String address, bool isBackedUp) async {
    final db = await database;
    await db.update(
      'wallets',
      {'is_backed_up': isBackedUp ? 1 : 0},
      where: 'address = ?',
      whereArgs: [address],
    );
  }
} 