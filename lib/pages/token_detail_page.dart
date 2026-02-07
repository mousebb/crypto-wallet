import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math';
import 'receive_page.dart';
import 'transfer_page.dart';
import '../services/wallet_service.dart';
import '../services/tron_scan_service.dart';
import '../main.dart';

class TokenDetailPage extends StatefulWidget {
  final String symbol;
  final String price;
  final String priceChange;
  final Color changeColor;
  final double quantity;
  final String tokenLogo;
  final double usdValue;
  final String tokenType;

  const TokenDetailPage({
    super.key,
    required this.symbol,
    required this.price,
    required this.priceChange,
    required this.changeColor,
    required this.quantity,
    required this.tokenLogo,
    required this.usdValue,
    required this.tokenType,
  });

  @override
  State<TokenDetailPage> createState() => _TokenDetailPageState();
}

class _TokenDetailPageState extends State<TokenDetailPage> {
  final TronScanService _tronScanService = TronScanService();
  final WalletService _walletService = WalletService();
  double _quantity = 0;
  double _usdValue = 0;
  String _price = '0';
  String _priceChange = '0%';
  Color _changeColor = Colors.green;
  bool _isRefreshing = false;
  bool _isLoadingTransactions = false;
  List<dynamic> _transactions = [];
  String _currentAddress = '';
  String _selectedFilter = 'all'; // 'all', 'incoming', 'outgoing'

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity;
    _usdValue = widget.usdValue;
    _price = widget.price;
    _priceChange = widget.priceChange;
    _changeColor = widget.changeColor;
    _loadWalletAddress();
  }

  Future<void> _loadWalletAddress() async {
    try {
      final walletData = await _walletService.getCurrentWallet();
      setState(() {
        _currentAddress = walletData.address;
      });
      _fetchTransactions();
    } catch (e) {
      print('Error loading wallet address: $e');
    }
  }

  Future<void> _fetchTransactions() async {
    if (_currentAddress.isEmpty) return;
    
    setState(() {
      _isLoadingTransactions = true;
    });
    
    try {
      final response = await _tronScanService.getTransactions(
        _currentAddress,
        tokenType: widget.tokenType,
        tokenAbbr: widget.symbol,
      );
      
      if (mounted) {
        setState(() {
          _transactions = response['data'] ?? [];
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('token_detail.transaction_error'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  List<dynamic> _getFilteredTransactions() {
    if (_selectedFilter == 'all') {
      return _transactions;
    } else if (_selectedFilter == 'incoming') {
      return _transactions.where((tx) => 
        tx['toAddress'] == _currentAddress && 
        tx['ownerAddress'] != _currentAddress
      ).toList();
    } else if (_selectedFilter == 'outgoing') {
      return _transactions.where((tx) => 
        tx['ownerAddress'] == _currentAddress && 
        tx['toAddress'] != _currentAddress
      ).toList();
    }
    return _transactions;
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatAmount(String amount, int decimals) {
    try {
      final value = double.parse(amount) / pow(10, decimals);
      if (value == 0) return '0';
      
      // Convert to string with full precision
      final formatted = value.toStringAsFixed(decimals);
      
      // Remove trailing zeros after decimal point
      final parts = formatted.split('.');
      if (parts.length == 1) return parts[0];
      
      final integerPart = parts[0];
      final decimalPart = parts[1].replaceAll(RegExp(r'0*$'), '');
      
      return decimalPart.isEmpty ? integerPart : '$integerPart.$decimalPart';
    } catch (e) {
      print('Error formatting amount: $e');
      return amount;
    }
  }

  String _formatPrice(String price) {
    try {
      final value = double.parse(price);
      return value.toStringAsFixed(3);
    } catch (e) {
      return price;
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final walletData = await _walletService.getCurrentWallet();
      
      // 获取最新的代币数据
      final tokens = await _tronScanService.getAccountTokens(walletData.address);
      final token = tokens.firstWhere(
        (t) => t['tokenAbbr']?.toString().toUpperCase() == widget.symbol,
        orElse: () => {},
      );

      if (token.isNotEmpty) {
        final decimals = token['tokenDecimal'] as int? ?? 6;
        final balance = double.tryParse(token['balance']?.toString() ?? '0') ?? 0.0;
        final quantity = balance / pow(10, decimals);
        final usdValue = double.tryParse(token['assetInUsd']?.toString() ?? '0') ?? 0.0;
        final tokenPrice = double.tryParse(token['tokenPriceInUsd']?.toString() ?? '0') ?? 0.0;
        final gain = double.tryParse(token['gain']?.toString() ?? '0') ?? 0.0;

        if (mounted) {
          setState(() {
            _quantity = quantity;
            _usdValue = usdValue;
            _price = tokenPrice.toString();
            _priceChange = '${gain.toStringAsFixed(2)}%';
            _changeColor = gain < 0 ? Colors.red : Colors.green;
          });
        }
      }
      
      // 刷新交易记录
      await _fetchTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('token_detail.refresh_error'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.symbol,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'token_detail.title'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.transparent,
                            child: widget.tokenLogo.startsWith('http')
                                ? Image.network(widget.tokenLogo)
                                : Image.asset('assets/images/trx_logo.png'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _quantity.toStringAsFixed(4),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'token_detail.usd_value'.tr(args: [_usdValue.toStringAsFixed(2)]),
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.03,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.04,
                        vertical: MediaQuery.of(context).size.height * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'token_detail.frozen'.tr(),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '0',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'token_detail.market_price'.tr(),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'token_detail.price_usd'.tr(args: [_formatPrice(_price)]),
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: MediaQuery.of(context).size.width * 0.04,
                                        vertical: MediaQuery.of(context).size.height * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _changeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _priceChange,
                                        style: TextStyle(
                                          color: _changeColor,
                                          fontSize: MediaQuery.of(context).size.width * 0.03,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.04,
                        vertical: MediaQuery.of(context).size.height * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = 'all';
                                    });
                                  },
                                  child: Text(
                                    'token_detail.all'.tr(),
                                    style: TextStyle(
                                      color: _selectedFilter == 'all' 
                                          ? Theme.of(context).primaryColor 
                                          : Colors.grey[400],
                                      fontWeight: _selectedFilter == 'all' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = 'incoming';
                                    });
                                  },
                                  child: Text(
                                    'token_detail.incoming'.tr(),
                                    style: TextStyle(
                                      color: _selectedFilter == 'incoming' 
                                          ? Theme.of(context).primaryColor 
                                          : Colors.grey[400],
                                      fontWeight: _selectedFilter == 'incoming' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = 'outgoing';
                                    });
                                  },
                                  child: Text(
                                    'token_detail.outgoing'.tr(),
                                    style: TextStyle(
                                      color: _selectedFilter == 'outgoing' 
                                          ? Theme.of(context).primaryColor 
                                          : Colors.grey[400],
                                      fontWeight: _selectedFilter == 'outgoing' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.filter_list, color: Colors.grey, size: 20),
                              ],
                            ),
                          ),
                          if (_isLoadingTransactions)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_getFilteredTransactions().isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 32),
                                  Icon(
                                    Icons.search_outlined,
                                    size: 48,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'token_detail.no_transactions'.tr(),
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: MediaQuery.of(context).size.width * 0.03,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'token_detail.view_explorer'.tr(),
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: MediaQuery.of(context).size.width * 0.03,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.4,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _getFilteredTransactions().length,
                                itemBuilder: (context, index) {
                                  final tx = _getFilteredTransactions()[index];
                                  final isIncoming = tx['toAddress'] == _currentAddress && tx['ownerAddress'] != _currentAddress;
                                  final timestamp = tx['timestamp'] ?? 0;
                                  final tokenInfo = tx['tokenInfo'] ?? {};
                                  final decimals = tokenInfo['tokenDecimal'] ?? 6;
                                  final amount = tx['amount'] ?? '0';
                                  final formattedAmount = _formatAmount(amount, decimals);
                                  
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Theme.of(context).dividerColor,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isIncoming ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                                            color: isIncoming ? Colors.green : Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isIncoming ? 'token_detail.received'.tr() : 'token_detail.sent'.tr(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatTimestamp(timestamp),
                                                style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width * 0.03,
                                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isIncoming ? '+' : '-'}$formattedAmount ${widget.symbol}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: isIncoming ? Colors.green : Colors.red,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              tx['contractRet'] == 'SUCCESS' ? 'token_detail.success'.tr() : 'token_detail.failed'.tr(),
                                              style: TextStyle(
                                                fontSize: MediaQuery.of(context).size.width * 0.03,
                                                color: tx['contractRet'] == 'SUCCESS' ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransferPage(
                            symbol: widget.symbol,
                            quantity: _quantity,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'token_detail.transfer'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.03,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final walletService = WalletService();
                      try {
                        final walletData = await walletService.getCurrentWallet();
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReceivePage(
                              address: walletData.address,
                              symbol: widget.symbol,
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('token_detail.get_address_error'.tr(args: [e.toString()]))),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'token_detail.receive'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.03,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 