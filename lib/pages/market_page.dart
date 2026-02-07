import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:k_chart/flutter_k_chart.dart';
import 'dart:async';
import '../services/market_service.dart';

class MarketPage extends StatefulWidget {
  final String symbol;
  final String name;

  const MarketPage({
    super.key,
    required this.symbol,
    required this.name,
  });

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> with SingleTickerProviderStateMixin {
  final _marketService = MarketService();
  List<KLineEntity>? kLineData;
  bool isLoading = true;
  bool isRefreshing = false;
  String currentPrice = "0.000";
  String priceChange = "0.00%";
  String volume24h = "\$0";
  String marketCap = "\$0";
  String totalSupply = "0";
  String holders = "0";
  String selectedInterval = "15m";
  bool isFavorite = false;
  Timer? _refreshTimer;

  late TabController _tabController;
  final List<String> _timeIntervals = ["1m", "5m", "15m", "30m", "1h", "4h", "1d", "1w"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMarketData();
    _fetchKLineData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMarketData() async {
    try {
      final marketData = await _marketService.getMarketData();
      
      if (mounted) {
        setState(() {
          currentPrice = "\$${marketData['price'].toStringAsFixed(4)}";
          priceChange = "${marketData['priceChange24h'].toStringAsFixed(2)}%";
          volume24h = _formatLargeNumber(marketData['volume24h']);
          marketCap = _formatLargeNumber(marketData['marketCap']);
          // 由于CoinGecko API不提供这些数据，暂时保持原值
          totalSupply = "295.585M";
          holders = "83,447";
        });
      }
    } catch (e) {
      debugPrint('Error fetching market data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is TimeoutException 
                ? 'market.timeout_error'.tr() 
                : 'market.fetch_error'.tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatLargeNumber(double number) {
    if (number >= 1000000000000) {
      return "\$${(number / 1000000000000).toStringAsFixed(2)}T";
    } else if (number >= 1000000000) {
      return "\$${(number / 1000000000).toStringAsFixed(2)}B";
    } else if (number >= 1000000) {
      return "\$${(number / 1000000).toStringAsFixed(2)}M";
    } else if (number >= 1000) {
      return "\$${(number / 1000).toStringAsFixed(2)}K";
    }
    return "\$${number.toStringAsFixed(2)}";
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
  }

  Future<void> _fetchKLineData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final kLineDataList = await _marketService.getKLineData(selectedInterval);
      
      if (kLineDataList.isNotEmpty) {
        kLineData = kLineDataList.map((item) {
          final time = item['time'] ?? item['t'] ?? 0;
          final open = double.parse((item['open'] ?? item['o'] ?? '0').toString());
          final high = double.parse((item['high'] ?? item['h'] ?? '0').toString());
          final low = double.parse((item['low'] ?? item['l'] ?? '0').toString());
          final close = double.parse((item['close'] ?? item['c'] ?? '0').toString());
          final vol = double.parse((item['volume'] ?? item['v'] ?? '0').toString());
          
          return KLineEntity.fromJson({
            'time': time,
            'open': open,
            'high': high,
            'low': low,
            'close': close,
            'vol': vol,
          });
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching K-line data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is TimeoutException 
                ? 'market.timeout_error'.tr() 
                : 'market.fetch_error'.tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      isRefreshing = true;
    });
    await _fetchMarketData();
    await _fetchKLineData(isRefresh: true);
    
    // Force rebuild the chart
    if (mounted) {
      setState(() {
        // This empty setState will force the widget to rebuild with the new data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/trx_logo.png',
              width: MediaQuery.of(context).size.width * 0.06,
              height: MediaQuery.of(context).size.width * 0.06,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'TRON',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              // TODO: Implement share
            },
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      currentPrice,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).size.width * 0.06,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.02,
                        vertical: MediaQuery.of(context).size.height * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: priceChange.startsWith('+') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priceChange,
                        style: TextStyle(
                          color: priceChange.startsWith('+') ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('market.volume_24h'.tr(), volume24h),
                    _buildInfoItem('market.market_cap'.tr(), marketCap),
                    _buildInfoItem('market.total_supply'.tr(), totalSupply),
                    _buildInfoItem('market.holders'.tr(), holders),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(text: 'market.k_line'.tr()),
              Tab(text: 'market.depth'.tr()),
              Tab(text: 'market.info'.tr()),
            ],
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.05,
            margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.01),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
              itemCount: _timeIntervals.length,
              itemBuilder: (context, index) {
                final interval = _timeIntervals[index];
                final isSelected = interval == selectedInterval;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedInterval = interval;
                      _fetchKLineData();
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.02),
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                      vertical: MediaQuery.of(context).size.height * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      interval,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // K线图
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: kLineData == null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (isLoading && !isRefreshing)
                            const Center(child: CircularProgressIndicator())
                          else
                            Center(child: Text('market.no_data'.tr())),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (isRefreshing)
                            Container(
                              height: MediaQuery.of(context).size.height * 0.002,
                              child: const LinearProgressIndicator(),
                            ),
                          Container(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                            height: MediaQuery.of(context).size.height * 0.5,
                            key: ValueKey('kline_chart_${DateTime.now().millisecondsSinceEpoch}'),
                            child: KChartWidget(
                              kLineData!,
                              ChartStyle(),
                              _createChartColors(isDarkMode),
                              isChinese: false,
                              isTrendLine: false,
                              mainState: MainState.MA,
                              secondaryState: SecondaryState.MACD,
                              maDayList: [5, 10, 30],
                              timeFormat: TimeFormat.YEAR_MONTH_DAY,
                            ),
                          ),
                        ],
                      ),
                ),
                // 深度图
                Center(child: Text('market.coming_soon'.tr())),
                // 信息
                Center(child: Text('market.coming_soon'.tr())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: MediaQuery.of(context).size.width * 0.025,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: MediaQuery.of(context).size.width * 0.028,
          ),
        ),
      ],
    );
  }

  ChartColors _createChartColors(bool isDarkMode) {
    final colors = ChartColors();
    
    if (isDarkMode) {
      colors.bgColor = [Colors.transparent, Colors.transparent];
      colors.kLineColor = Colors.white;
      colors.gridColor = Colors.grey[800]!;
      colors.ma5Color = Colors.blue;
      colors.ma10Color = Colors.yellow;
      colors.ma30Color = Colors.purple;
      colors.upColor = Colors.green;
      colors.dnColor = Colors.red;
      colors.volColor = Colors.grey[400]!;
      colors.macdColor = Colors.grey[400]!;
      colors.difColor = Colors.blue;
      colors.deaColor = Colors.yellow;
      colors.kColor = Colors.blue;
      colors.dColor = Colors.yellow;
      colors.jColor = Colors.purple;
      colors.rsiColor = Colors.blue;
      colors.lineFillColor = Colors.blue.withOpacity(0.1);
    } else {
      colors.bgColor = [Colors.transparent, Colors.transparent];
      colors.kLineColor = Colors.black;
      colors.gridColor = Colors.grey[200]!;
      colors.ma5Color = Colors.blue;
      colors.ma10Color = Colors.amber[800]!;
      colors.ma30Color = Colors.purple;
      colors.upColor = Colors.green;
      colors.dnColor = Colors.red;
      colors.volColor = Colors.grey[700]!;
      colors.macdColor = Colors.grey[700]!;
      colors.difColor = Colors.blue;
      colors.deaColor = Colors.amber[800]!;
      colors.kColor = Colors.blue;
      colors.dColor = Colors.amber[800]!;
      colors.jColor = Colors.purple;
      colors.rsiColor = Colors.blue;
      colors.lineFillColor = Colors.blue.withOpacity(0.1);
    }
    
    return colors;
  }
} 