import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io' show Platform, File, Directory;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/wallet_service.dart';
import 'services/database_service.dart';
import 'services/wallet_generator_service.dart';
import 'services/theme_service.dart';
import 'pages/wallet_guide_page.dart';
import 'pages/wallet_detail_page.dart';
import 'pages/mnemonic_display_page.dart';
import 'pages/token_detail_page.dart';
import 'pages/profile_page.dart';
import 'pages/transfer_page.dart';
import 'pages/receive_page.dart';
import 'pages/select_network_page.dart';
import 'pages/create_wallet_page.dart';
import 'pages/import_wallet_page.dart';
import 'services/tron_scan_service.dart';
import 'pages/market_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'pages/trade_page.dart';
import 'pages/mnemonic_page.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  try {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
      } else {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      
      final dbService = DatabaseService();
      await dbService.initializeDatabase();
    }
    
    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'), // English
          Locale('zh'), // Chinese
          Locale('ja'), // Japanese
          Locale('ko'), // Korean
          Locale('es'), // Spanish
          Locale('fr'), // French
          Locale('de'), // German
          Locale('ru'), // Russian
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: ChangeNotifierProvider(
          create: (_) => ThemeService(),
          child: const MainApp(),
        ),
      ),
    );
  } catch (e) {
    print('Error initializing app: $e');
    runApp(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
        ),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'main.error_initializing'.tr(args: [e.toString()]),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    main();
                  },
                  child: Text('main.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: context.watch<ThemeService>().theme,
      home: const WalletCheckPage(),
    );
  }
}

class WalletCheckPage extends StatefulWidget {
  const WalletCheckPage({super.key});

  @override
  State<WalletCheckPage> createState() => _WalletCheckPageState();
}

class _WalletCheckPageState extends State<WalletCheckPage> {
  final WalletService _walletService = WalletService();
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkWallet();
  }

  Future<void> _checkWallet() async {
    try {
      final hasWallet = await _walletService.hasWallet();
      if (!mounted) return;

      if (hasWallet) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WalletGuidePage(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('main.error'.tr(args: [_error ?? ''])),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _checkWallet();
                },
                child: Text('main.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WalletService _walletService = WalletService();
  final DatabaseService _databaseService = DatabaseService();
  final TronScanService _tronScanService = TronScanService();
  WalletData? _walletData;
  bool _isLoading = true;
  bool _isAmountVisible = true;
  double _trxBalance = 0.0;
  double _trxPrice = 0.0;
  String _trxPriceChange = '0.00%';
  List<Map<String, dynamic>> _tokens = [];
  bool _isRefreshing = false;
  double _totalAssetInUsd = 0.0;
  int _currentIndex = 0;

  late final List<Widget> _pages;

  void _updateAssetPage() {
    _pages[0] = AssetPage(
      isLoading: _isLoading,
      walletData: _walletData,
      isAmountVisible: _isAmountVisible,
      totalAssetInUsd: _totalAssetInUsd,
      onRefresh: _loadWalletData,
      onToggleAmountVisibility: toggleAmountVisibility,
      formatAddress: _formatAddress,
      onBackupWallet: _navigateToBackup,
      onWalletDetail: _navigateToWalletDetail,
      buildActionButton: _buildActionButton,
      tokens: _tokens,
    );
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      AssetPage(
        isLoading: _isLoading,
        walletData: _walletData,
        isAmountVisible: _isAmountVisible,
        totalAssetInUsd: _totalAssetInUsd,
        onRefresh: _loadWalletData,
        onToggleAmountVisibility: toggleAmountVisibility,
        formatAddress: _formatAddress,
        onBackupWallet: _navigateToBackup,
        onWalletDetail: _navigateToWalletDetail,
        buildActionButton: _buildActionButton,
        tokens: _tokens,
      ),
      const MarketPage(symbol: 'TRX', name: 'TRX'),
      const TradePage(),
      Center(child: Text('home.discover'.tr())),
      const ProfilePage(),
    ];
    _loadWalletData();
  }

  void _navigateToBackup(BuildContext context) {
    if (_walletData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MnemonicPage(
            mnemonic: _walletData!.mnemonic,
            walletAddress: _walletData!.address,
          ),
        ),
      ).then((value) {
        if (value == true) {
          _loadWalletData();
        }
      });
    }
  }

  void _navigateToWalletDetail(BuildContext context) {
    if (_walletData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WalletDetailPage(
            address: _walletData!.address,
          ),
        ),
      );
    }
  }

  void toggleAmountVisibility() {
    setState(() {
      _isAmountVisible = !_isAmountVisible;
      _updateAssetPage();
    });
  }

  Future<void> _setCurrentWallet(String address) async {
    try {
      final db = await _databaseService.database;
      
      // First, set all wallets' is_current to 0
      await db.update(
        'wallets',
        {'is_current': 0},
      );
      
      // Then set the selected wallet's is_current to 1
      await db.update(
        'wallets',
        {'is_current': 1},
        where: 'address = ?',
        whereArgs: [address],
      );
    } catch (e) {
      print('Error setting current wallet: $e');
      rethrow;
    }
  }

  Future<void> _loadWalletData() async {
    try {
      final walletData = await _walletService.getCurrentWallet();
      if (mounted) {
        setState(() {
          _walletData = walletData;
          _isLoading = false;
          _updateAssetPage();
        });
        _loadBalanceAndTokens();
      }
    } catch (e) {
      print('Error loading wallet data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _updateAssetPage();
        });
      }
    }
  }

  Future<void> _loadBalanceAndTokens() async {
    if (_walletData == null || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _isLoading = true;
      _updateAssetPage();
    });

    try {
      // Get TRX balance
      final trxBalance = await _tronScanService.getTrxBalance(_walletData!.address);
      
      // Get TRX market info
      final marketInfo = await _tronScanService.getTrxMarketInfo();
      final price = marketInfo['priceUSD'] ?? 0.0;
      final priceChange = marketInfo['percentage'] ?? 0.0;
      
      // Get token list
      final tokens = await _tronScanService.getAccountTokens(_walletData!.address);
      
      // If no tokens returned, create default token list with TRX and USDT
      if (tokens.isEmpty) {
        tokens.addAll([
          {
            'tokenAbbr': 'TRX',
            'tokenName': 'TRON',
            'tokenDecimal': 6,
            'balance': '0',
            'tokenLogo': 'assets/images/trx_logo.png',
            'tokenPriceInUsd': price.toString(),
            'assetInUsd': '0',
            'gain': priceChange,
          },
          {
            'tokenAbbr': 'USDT',
            'tokenName': 'Tether USD',
            'tokenDecimal': 6,
            'balance': '0',
            'tokenLogo': 'assets/images/usdt_logo.png',
            'tokenPriceInUsd': '1',
            'assetInUsd': '0',
            'gain': 0,
          }
        ]);
      }
      
      // Get total asset value in USD
      final totalAssetInUsd = await _tronScanService.getTotalAssetInUsd(_walletData!.address);

      if (mounted) {
        setState(() {
          _trxBalance = trxBalance;
          _trxPrice = price;
          _trxPriceChange = '${priceChange.toStringAsFixed(2)}%';
          _tokens = tokens;
          _totalAssetInUsd = totalAssetInUsd;
          _isRefreshing = false;
          _isLoading = false;
          _updateAssetPage();
        });
      }
    } catch (e) {
      print('Error loading balance and tokens: $e');
      if (mounted) {
        setState(() {
          _trxBalance = 0.0;
          _trxPrice = 0.0;
          _trxPriceChange = '0.00%';
          _tokens = [];
          _totalAssetInUsd = 0.0;
          _isRefreshing = false;
          _isLoading = false;
          _updateAssetPage();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('home.load_balance_failed'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  String _formatAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _showTokenSelectionSheet(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    final ValueNotifier<List<Map<String, dynamic>>> filteredTokens = ValueNotifier<List<Map<String, dynamic>>>(_tokens);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[50],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'main.token_selection.transfer_title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'main.token_selection.search_hint'.tr(),
                          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                        onChanged: (value) {
                          filteredTokens.value = _tokens.where((token) {
                            final symbol = token['tokenAbbr']?.toString().toLowerCase() ?? '';
                            return symbol.contains(value.toLowerCase());
                          }).toList();
                        },
                      ),
                    ),
                    if (searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                        onPressed: () {
                          searchController.clear();
                          filteredTokens.value = _tokens;
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: filteredTokens,
                  builder: (context, tokens, child) {
                    if (tokens.isEmpty) {
                      return Center(
                        child: Text(
                          'main.token_selection.no_results'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: tokens.length,
                      itemBuilder: (context, index) {
                        final token = tokens[index];
                        final decimals = token['tokenDecimal'] as int? ?? 6;
                        final balance = double.tryParse(token['balance']?.toString() ?? '0') ?? 0.0;
                        final quantity = balance / pow(10, decimals);
                        
                        final usdValue = double.tryParse(token['assetInUsd']?.toString() ?? '0') ?? 0.0;
                        final tokenPrice = double.tryParse(token['tokenPriceInUsd']?.toString() ?? '0') ?? 0.0;
                        final gain = double.tryParse(token['gain']?.toString() ?? '0') ?? 0.0;
                        final changeColor = gain < 0 ? Colors.red : Colors.green;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: token['tokenLogo']?.toString().startsWith('http') == true
                                ? Image.network(
                                    token['tokenLogo'],
                                    width: MediaQuery.of(context).size.width * 0.08,
                                    height: MediaQuery.of(context).size.width * 0.08,
                                    fit: BoxFit.contain,
                                  )
                                : Image.asset(
                                    token['tokenLogo'] ?? 'assets/images/trx_logo.png',
                                    width: MediaQuery.of(context).size.width * 0.08,
                                    height: MediaQuery.of(context).size.width * 0.08,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                token['tokenAbbr']?.toString().toUpperCase() ?? '',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  token['tokenType']?.toString().toUpperCase() ?? 'TRC10',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '\$${tokenPrice.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                quantity.toStringAsFixed(4),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '≈ \$${usdValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: changeColor,
                                  fontSize: MediaQuery.of(context).size.width * 0.03,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransferPage(
                                  symbol: token['tokenAbbr']?.toString().toUpperCase() ?? '',
                                  quantity: quantity,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReceiveTokenSelectionSheet(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    final ValueNotifier<List<Map<String, dynamic>>> filteredTokens = ValueNotifier<List<Map<String, dynamic>>>(_tokens);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[50],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'main.token_selection.receive_title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'main.token_selection.search_hint'.tr(),
                          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                        onChanged: (value) {
                          filteredTokens.value = _tokens.where((token) {
                            final symbol = token['tokenAbbr']?.toString().toLowerCase() ?? '';
                            return symbol.contains(value.toLowerCase());
                          }).toList();
                        },
                      ),
                    ),
                    if (searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                        onPressed: () {
                          searchController.clear();
                          filteredTokens.value = _tokens;
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: filteredTokens,
                  builder: (context, tokens, child) {
                    if (tokens.isEmpty) {
                      return Center(
                        child: Text(
                          'main.token_selection.no_results'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: tokens.length,
                      itemBuilder: (context, index) {
                        final token = tokens[index];
                        final decimals = token['tokenDecimal'] as int? ?? 6;
                        final balance = double.tryParse(token['balance']?.toString() ?? '0') ?? 0.0;
                        final quantity = balance / pow(10, decimals);
                        
                        final usdValue = double.tryParse(token['assetInUsd']?.toString() ?? '0') ?? 0.0;
                        final tokenPrice = double.tryParse(token['tokenPriceInUsd']?.toString() ?? '0') ?? 0.0;
                        final gain = double.tryParse(token['gain']?.toString() ?? '0') ?? 0.0;
                        final changeColor = gain < 0 ? Colors.red : Colors.green;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: token['tokenLogo']?.toString().startsWith('http') == true
                                ? Image.network(
                                    token['tokenLogo'],
                                    width: MediaQuery.of(context).size.width * 0.08,
                                    height: MediaQuery.of(context).size.width * 0.08,
                                    fit: BoxFit.contain,
                                  )
                                : Image.asset(
                                    token['tokenLogo'] ?? 'assets/images/trx_logo.png',
                                    width: MediaQuery.of(context).size.width * 0.08,
                                    height: MediaQuery.of(context).size.width * 0.08,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                token['tokenAbbr']?.toString().toUpperCase() ?? '',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  token['tokenType']?.toString().toUpperCase() ?? 'TRC10',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '\$${tokenPrice.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                quantity.toStringAsFixed(4),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '≈ \$${usdValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: changeColor,
                                  fontSize: MediaQuery.of(context).size.width * 0.03,
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            try {
                              final walletService = WalletService();
                              final walletData = await walletService.getCurrentWallet();
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReceivePage(
                                      address: walletData.address,
                                      symbol: token['tokenAbbr']?.toString().toUpperCase() ?? '',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('main.token_selection.get_address_failed'.tr(args: [e.toString()])),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showWalletListSheet(BuildContext context) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> allWallets = await db.query('wallets');
      
      // Create a TextEditingController for the search field
      final TextEditingController searchController = TextEditingController();
      // Create a ValueNotifier to hold the filtered wallets
      final ValueNotifier<List<Map<String, dynamic>>> filteredWallets = ValueNotifier<List<Map<String, dynamic>>>(allWallets);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[50],
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: MediaQuery.of(context).size.width * 0.04,
                          backgroundColor: Colors.red,
                          child: Image.asset(
                            'assets/images/trx_logo.png',
                            width: MediaQuery.of(context).size.width * 0.05,
                            height: MediaQuery.of(context).size.width * 0.05,
                          ),
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Text(
                          'main.wallet_list.tron'.tr(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ImportWalletPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'main.wallet_list.search_hint'.tr(),
                            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                          onChanged: (value) {
                            // Filter wallets based on search text
                            if (value.isEmpty) {
                              filteredWallets.value = allWallets;
                            } else {
                              filteredWallets.value = allWallets.where((wallet) {
                                final name = wallet['name'] as String;
                                return name.toLowerCase().contains(value.toLowerCase());
                              }).toList();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                        onPressed: () {
                          searchController.clear();
                          filteredWallets.value = allWallets;
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: filteredWallets,
                    builder: (context, wallets, child) {
                      if (wallets.isEmpty) {
                        return Center(
                          child: Text(
                            'main.wallet_list.no_results'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: wallets.length,
                        itemBuilder: (context, index) {
                          final wallet = wallets[index];
                          final isSelected = wallet['address'] == _walletData?.address;
                          final isBackedUp = wallet['is_backed_up'] == 1;
                          
                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.04,
                              vertical: MediaQuery.of(context).size.height * 0.008,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[850]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                wallet['name'] as String,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    _formatAddress(wallet['address'] as String),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 4),
                                  if (!isBackedUp) 
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'main.wallet_list.not_backed_up'.tr(),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isSelected 
                                ? Icon(Icons.check, color: Theme.of(context).iconTheme.color)
                                : null,
                              onTap: () async {
                                if (!isSelected) {
                                  try {
                                    final walletData = WalletData(
                                      mnemonic: wallet['mnemonic'] as String,
                                      privateKey: wallet['private_key'] as String,
                                      address: wallet['address'] as String,
                                      name: wallet['name'] as String,
                                      isBackedUp: isBackedUp,
                                    );
                                    
                                    // Save the selected wallet as current
                                    await _setCurrentWallet(walletData.address);
                                    
                                    if (mounted) {
                                      setState(() {
                                        _walletData = walletData;
                                      });
                                      
                                      // Close the bottom sheet first
                                      Navigator.pop(context);
                                      
                                      // Reload wallet data and balance
                                      _loadWalletData();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('main.wallet_list.switch_failed'.tr(args: [e.toString()])),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取钱包列表失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () {
          if (label == 'home.transfer'.tr()) {
            _showTokenSelectionSheet(context);
          } else if (label == 'home.receive'.tr()) {
            _showReceiveTokenSelectionSheet(context);
          }
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 28,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _showWalletOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[50],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'main.wallet_options.title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWalletOptionButton(
                context,
                'main.wallet_options.create'.tr(),
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWalletPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildWalletOptionButton(
                context,
                'main.wallet_options.import'.tr(),
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImportWalletPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildWalletOptionButton(
                context,
                'main.wallet_options.close'.tr(),
                () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletOptionButton(BuildContext context, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showWalletListSheet(context),
        ),
        title: Text('home.wallet'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => _showWalletOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              try {
                final picker = ImagePicker();
                await picker.pickImage(source: ImageSource.camera);
                // TODO: 处理扫描结果
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('home.camera_error'.tr(args: [e.toString()]))),
                  );
                }
              }
            },
          ),
        ],
      ) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        ),
        child: BottomNavigationBar(
          selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet), label: 'home.assets'.tr()),
            BottomNavigationBarItem(icon: const Icon(Icons.show_chart), label: 'home.market'.tr()),
            BottomNavigationBarItem(icon: const Icon(Icons.swap_horiz), label: 'home.trade'.tr()),
            BottomNavigationBarItem(icon: const Icon(Icons.explore), label: 'home.discover'.tr()),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'home.profile'.tr()),
          ],
        ),
      ),
    );
  }
}

class AssetPage extends StatelessWidget {
  final bool isLoading;
  final WalletData? walletData;
  final bool isAmountVisible;
  final double totalAssetInUsd;
  final Future<void> Function() onRefresh;
  final VoidCallback onToggleAmountVisibility;
  final String Function(String) formatAddress;
  final Function(BuildContext) onBackupWallet;
  final Function(BuildContext) onWalletDetail;
  final Widget Function(IconData, String) buildActionButton;
  final List<Map<String, dynamic>> tokens;

  const AssetPage({
    super.key,
    required this.isLoading,
    required this.walletData,
    required this.isAmountVisible,
    required this.totalAssetInUsd,
    required this.onRefresh,
    required this.onToggleAmountVisibility,
    required this.formatAddress,
    required this.onBackupWallet,
    required this.onWalletDetail,
    required this.buildActionButton,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当前主题模式
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 定义日夜模式的颜色
    final cardBackgroundColor = isDarkMode
        ? const Color(0xFF1F1F1F)  // 深灰色背景用于夜间模式
        : const Color(0xFFF5F5F5); // 浅灰色背景用于日间模式
    
    final cardBorderColor = isDarkMode
        ? const Color(0xFF2C2C2C)  // 深色边框用于夜间模式
        : const Color(0xFFEEEEEE); // 浅色边框用于日间模式
    
    final tagBackgroundColor = isDarkMode
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFEEEEEE);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.04,
                    vertical: MediaQuery.of(context).size.height * 0.02,
                  ),
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (walletData != null)
                            Row(
                              children: [
                                Text(
                                  walletData!.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MediaQuery.of(context).size.width * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Text(
                                  'home.loading'.tr(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MediaQuery.of(context).size.width * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          Row(
                            children: [
                              if (walletData != null && !walletData!.isBackedUp)
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MnemonicPage(
                                          mnemonic: walletData!.mnemonic,
                                          walletAddress: walletData!.address,
                                        ),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        onRefresh();
                                      }
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('home.backup_now'.tr()),
                                ),
                              IconButton(
                                icon: const Icon(Icons.more_horiz, color: Colors.white),
                                onPressed: () => onWalletDetail(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (walletData != null)
                        Text(
                          formatAddress(walletData!.address),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            isAmountVisible 
                              ? '\$${totalAssetInUsd.toStringAsFixed(2)}'
                              : '***',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width * 0.06,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onToggleAmountVisibility,
                            child: Icon(
                              isAmountVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.08,
                  ),
                  child: Builder(
                    builder: (context) {
                      // Force rebuild when locale changes
                      context.locale;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildActionButton(Icons.swap_horiz, 'home.transfer'.tr()),
                          buildActionButton(Icons.download, 'home.receive'.tr()),
                          buildActionButton(Icons.settings, 'home.resources'.tr()),
                          buildActionButton(Icons.more_horiz, 'home.more_tools'.tr()),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  child: Row(
                    children: [
                      Text(
                        'home.assets'.tr(),
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                      const Spacer(),
                      const Icon(Icons.search)
                    ],
                  ),
                ),
                if (tokens.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'home.no_assets'.tr(),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tokens.length,
                    itemBuilder: (context, index) {
                      final token = tokens[index];
                      final decimals = token['tokenDecimal'] as int? ?? 6;
                      final balance = double.tryParse(token['balance']?.toString() ?? '0') ?? 0.0;
                      final quantity = balance / pow(10, decimals);
                      
                      final usdValue = double.tryParse(token['assetInUsd']?.toString() ?? '0') ?? 0.0;
                      final tokenPrice = double.tryParse(token['tokenPriceInUsd']?.toString() ?? '0') ?? 0.0;
                      final gain = double.tryParse(token['gain']?.toString() ?? '0') ?? 0.0;
                      final changeColor = gain < 0 ? Colors.red : Colors.green;

                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.04,
                          vertical: MediaQuery.of(context).size.height * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: cardBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: token['tokenLogo']?.toString().startsWith('http') == true
                                ? Image.network(
                                    token['tokenLogo'],
                                    width: MediaQuery.of(context).size.width * 0.08,
                                    height: MediaQuery.of(context).size.width * 0.08,
                                    fit: BoxFit.contain,
                                  )
                                : Image.asset(
                                    token['tokenLogo'] ?? 'assets/images/trx_logo.png',
                                    width: MediaQuery.of(context).size.width * 0.08,
                                    height: MediaQuery.of(context).size.width * 0.08,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                token['tokenAbbr']?.toString().toUpperCase() ?? '',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tagBackgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  token['tokenType']?.toString().toUpperCase() ?? 'TRC10',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '\$${tokenPrice.toStringAsFixed(4)}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                quantity.toStringAsFixed(4),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                '≈ \$${usdValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: changeColor,
                                  fontSize: MediaQuery.of(context).size.width * 0.028,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TokenDetailPage(
                                  symbol: token['tokenAbbr']?.toString().toUpperCase() ?? '',
                                  price: tokenPrice.toString(),
                                  priceChange: '${gain.toStringAsFixed(2)}%',
                                  changeColor: changeColor,
                                  quantity: quantity,
                                  tokenLogo: token['tokenLogo']?.toString() ?? '',
                                  usdValue: usdValue,
                                  tokenType: token['tokenType']?.toString().toLowerCase() ?? 'trc10',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'home.loading_assets'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
