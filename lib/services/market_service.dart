import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

class MarketService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static const String _binanceUrl = 'https://api.binance.com/api/v3';
  static const String _tronId = 'tron';
  
  // 默认市场数据
  static const Map<String, dynamic> _dummyMarketData = {
    'price': 0.234614,
    'priceChange24h': 3.1279321741770443,
    'volume24h': 728844986.2395185,
    'marketCap': 22265330901.19912,
  };
  
  // 从JSON文件加载默认K线数据
  static Future<List<List<dynamic>>> _loadDummyKLineData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/dummy_kline_data.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      print('MarketService: Successfully loaded dummy K-line data from JSON file');
      return jsonData.cast<List<dynamic>>();
    } catch (e) {
      print('MarketService: Error loading dummy K-line data from JSON: $e');
      // 返回一个空列表作为后备
      return [];
    }
  }
  
  Future<Map<String, dynamic>> getMarketData() async {
    print('MarketService: Using default market data');
    return _dummyMarketData;

    // try {
    //   print('MarketService: Fetching TRX market data from CoinGecko API...');
    //   final url = '$_baseUrl/simple/price?ids=$_tronId&vs_currencies=usd&include_24hr_vol=true&include_24hr_change=true&include_market_cap=true';
    //   print('MarketService: Request URL: $url');
      
    //   // 获取TRX价格数据
    //   final trxResponse = await http.get(
    //     Uri.parse(url),
    //   ).timeout(
    //     const Duration(seconds: 15),
    //     onTimeout: () {
    //       print('MarketService: Request timed out after 15 seconds');
    //       throw TimeoutException('Request timed out');
    //     },
    //   );

    //   print('MarketService: Response status code: ${trxResponse.statusCode}');
      
    //   if (trxResponse.statusCode == 200) {
    //     final trxData = json.decode(trxResponse.body)[_tronId];
    //     print('MarketService: Successfully fetched TRX data: $trxData');
        
    //     final result = {
    //       'price': trxData['usd'],
    //       'priceChange24h': trxData['usd_24h_change'],
    //       'volume24h': trxData['usd_24h_vol'],
    //       'marketCap': trxData['usd_market_cap'],
    //     };
        
    //     print('MarketService: Processed market data: $result');
    //     return result;
    //   } else {
    //     print('MarketService: Failed to fetch market data. Status code: ${trxResponse.statusCode}');
    //     print('MarketService: Response body: ${trxResponse.body}');
    //     throw Exception('Failed to fetch market data');
    //   }
    // } catch (e) {
    //   print('MarketService: Error fetching market data: $e');
    // }
  }

  Future<List<Map<String, dynamic>>> getKLineData(String interval) async {
    print('MarketService: Using default K-line data for interval: $interval');
    
    try {
      final dummyData = await _loadDummyKLineData();
      final result = dummyData.map((item) {
        return {
          'time': item[0],
          'open': double.parse(item[1]),
          'high': double.parse(item[2]),
          'low': double.parse(item[3]),
          'close': double.parse(item[4]),
          'volume': double.parse(item[5]),
          'closeTime': item[6],
          'quoteVolume': double.parse(item[7]),
          'trades': item[8],
          'takerBuyBaseVolume': double.parse(item[9]),
          'takerBuyQuoteVolume': double.parse(item[10]),
        };
      }).toList();
      
      print('MarketService: Successfully loaded ${result.length} default K-line data points');
      if (result.isNotEmpty) {
        print('MarketService: First default K-line data point: ${result.first}');
        print('MarketService: Last default K-line data point: ${result.last}');
      }
      return result;
    } catch (e) {
      print('MarketService: Error processing default K-line data: $e');
      throw Exception('Failed to process default K-line data: $e');
    }
  }

  String _convertInterval(String interval) {
    print('MarketService: Converting interval: $interval');
    String result;
    switch (interval) {
      case '1m': result = '1m'; break;
      case '5m': result = '5m'; break;
      case '15m': result = '15m'; break;
      case '30m': result = '30m'; break;
      case '1h': result = '1h'; break;
      case '4h': result = '4h'; break;
      case '1d': result = '1d'; break;
      case '1w': result = '1w'; break;
      default: result = '1h'; break;
    }
    print('MarketService: Converted interval: $interval -> $result');
    return result;
  }
} 