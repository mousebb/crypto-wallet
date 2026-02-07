import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class TronScanService {
  static const String _baseUrl = 'https://apilist.tronscanapi.com/api';
  final http.Client _client;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  TronScanService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'User-Agent': 'TronWallet/1.0',
  };

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= _maxRetries) {
          rethrow;
        }
        await Future.delayed(_retryDelay * attempts);
      }
    }
  }

  Future<Map<String, dynamic>> getAccountInfo(String address) async {
    return _withRetry(() async {
      try {
        final response = await _client.get(
          Uri.parse('$_baseUrl/accountv2?address=$address'),
          headers: _headers,
        );

        if (response.statusCode == 200) {
          print('Account Info API Response: ${response.body}');
          final data = json.decode(response.body);
          return data;
        } else {
          print('Account Info API Error: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to load account info: ${response.statusCode}');
        }
      } catch (e) {
        print('Account Info API Exception: $e');
        throw Exception('Error getting account info: $e');
      }
    });
  }

  Future<Map<String, dynamic>> getTokenPrice(String tokenId) async {
    return _withRetry(() async {
      try {
        final response = await _client.get(
          Uri.parse('$_baseUrl/token_trc20/price?token_id=$tokenId'),
          headers: _headers,
        );

        if (response.statusCode == 200) {
          print('Token Price API Response: ${response.body}');
          final data = json.decode(response.body);
          return data;
        } else {
          print('Token Price API Error: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to load token price: ${response.statusCode}');
        }
      } catch (e) {
        print('Token Price API Exception: $e');
        throw Exception('Error getting token price: $e');
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAccountTokens(String address) async {
    try {
      print('Fetching account tokens for address: $address');
      final response = await http.get(
        Uri.parse('$_baseUrl/account/token_asset_overview?address=$address'),
        headers: _headers,
      );

      print('Account tokens response status: ${response.statusCode}');
      print('Account tokens response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('No token data found in response');
          return [];
        }
      } else {
        print('Failed to fetch account tokens: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching account tokens: $e');
      return [];
    }
  }

  Future<double> getTrxBalance(String address) async {
    return _withRetry(() async {
      try {
        final response = await _client.get(
          Uri.parse('$_baseUrl/accountv2?address=$address'),
          headers: _headers,
        );

        if (response.statusCode == 200) {
          print('TRX Balance API Response: ${response.body}');
          final data = json.decode(response.body);
          if (data['balance'] != null) {
            final balance = data['balance'] ?? 0;
            print('Extracted balance: $balance (in sun)');
            print('Converted balance: ${balance / 1000000} (in TRX)');
            return balance / 1000000; // Convert from sun to TRX
          }
          return 0.0;
        } else {
          print('TRX Balance API Error: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to load TRX balance: ${response.statusCode}');
        }
      } catch (e) {
        print('TRX Balance API Exception: $e');
        throw Exception('Error getting TRX balance: $e');
      }
    });
  }

  Future<Map<String, dynamic>> getTrxMarketInfo() async {
    return _withRetry(() async {
      try {
        final response = await _client.get(
          Uri.parse('$_baseUrl/tokens/overview?start=0&limit=2&verifier=all&order=desc&filter=top&sort=&showAll=1&field='),
          headers: _headers,
        );

        if (response.statusCode == 200) {
          print('Market Info API Response: ${response.body}');
          final data = json.decode(response.body);
          
          // Find TRX token in the tokens array
          final trxToken = data['tokens']?.firstWhere(
            (token) => token['abbr'] == 'TRON' || token['abbr'] == 'TRX',
            orElse: () => null,
          );
          
          if (trxToken != null) {
            return {
              'priceUSD': trxToken['priceInUsd'] ?? 0.0,
              'percentage': trxToken['gain'] ?? 0.0,
              'volume24h': trxToken['volume24hInTrx'] ?? 0.0,
              'marketCap': trxToken['marketcap'] ?? 0.0,
            };
          }
          
          // Fallback if TRX token not found
          return {
            'priceUSD': 0.0,
            'percentage': 0.0,
            'volume24h': 0.0,
            'marketCap': 0.0,
          };
        } else {
          print('Market Info API Error: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to load TRX market info: ${response.statusCode}');
        }
      } catch (e) {
        print('Market Info API Exception: $e');
        throw Exception('Error getting TRX market info: $e');
      }
    });
  }

  Future<double> getTotalAssetInUsd(String address) async {
    try {
      print('Fetching total asset value in USD for address: $address');
      final response = await http.get(
        Uri.parse('$_baseUrl/account/token_asset_overview?address=$address'),
        headers: _headers,
      );

      print('Total asset value response status: ${response.statusCode}');
      print('Total asset value response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totalAssetInUsd = double.tryParse(data['totalAssetInUsd']?.toString() ?? '0') ?? 0.0;
        print('Total asset value in USD: $totalAssetInUsd');
        return totalAssetInUsd;
      } else {
        print('Failed to fetch total asset value: ${response.statusCode}');
        return 0.0;
      }
    } catch (e) {
      print('Error fetching total asset value: $e');
      return 0.0;
    }
  }

  /// Fetches transaction history for a given address
  /// 
  /// [address] - The TRON address to fetch transactions for
  /// [tokenType] - Type of token ('trc10' or 'trc20')
  /// [tokenAbbr] - Token abbreviation to filter transfers (e.g., 'USDT')
  /// [limit] - Maximum number of transactions to return (default: 10)
  /// [start] - Starting position for pagination (default: 0)
  /// [sort] - Sort order for transactions (default: -timestamp for newest first)
  /// 
  /// Returns a map containing transaction data and metadata
  Future<Map<String, dynamic>> getTransactions(
    String address, {
    String tokenType = 'trc10',
    String? tokenAbbr,
    int limit = 10,
    int start = 0,
    String sort = '-timestamp',
  }) async {
    return _withRetry(() async {
      try {
        print('Fetching $tokenType transactions for address: $address${tokenAbbr != null ? ', token: $tokenAbbr' : ''}');
        
        // Determine which API endpoint to use based on tokenType
        final String endpoint = tokenType.toLowerCase() == 'trc20' 
            ? '$_baseUrl/token_trc20/transfers?limit=$limit&start=$start&sort=$sort&filterTokenValue=0&relatedAddress=$address'
            : '$_baseUrl/transaction?address=$address&limit=$limit&sort=$sort';
        
        final response = await _client.get(
          Uri.parse(endpoint),
          headers: _headers,
        );

        print('Transaction history response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // Process TRC20 transfers
          if (tokenType.toLowerCase() == 'trc20') {
            // Filter transfers by token abbreviation if specified
            if (tokenAbbr != null && data['token_transfers'] != null) {
              final filteredTransfers = (data['token_transfers'] as List)
                  .where((transfer) => 
                      transfer['tokenInfo']?['tokenAbbr']?.toString().toUpperCase() == tokenAbbr.toUpperCase())
                  .toList();
              
              data['token_transfers'] = filteredTransfers;
              data['total'] = filteredTransfers.length;
            }
            
            // Restructure TRC20 data to match the format expected by token_detail_page
            final List<dynamic> restructuredData = [];
            if (data['token_transfers'] != null) {
              for (var transfer in data['token_transfers']) {
                // Skip transfers with zero amount
                if (transfer['quant'] == '0' || transfer['quant'] == '0.0') {
                  print('Skipping transfer with zero amount');
                  continue;
                }

                restructuredData.add({
                  'timestamp': transfer['block_ts'],
                  'ownerAddress': transfer['from_address'],
                  'toAddress': transfer['to_address'],
                  'amount': transfer['quant'],
                  'tokenInfo': {
                    'tokenId': transfer['tokenInfo']['tokenId'],
                    'tokenAbbr': transfer['tokenInfo']['tokenAbbr'],
                    'tokenName': transfer['tokenInfo']['tokenName'],
                    'tokenDecimal': transfer['tokenInfo']['tokenDecimal'],
                    'tokenType': 'trc20',
                  },
                  'contractRet': transfer['contractRet'] ?? 'SUCCESS',
                  'transactionId': transfer['transaction_id'],
                });
              }
            }
            
            return {
              'data': restructuredData,
              'total': data['total'] ?? restructuredData.length,
            };
          } 
          // Process TRC10 transactions
          else {
            print('Processing TRC10 transactions...');
            print('Raw response data: ${json.encode(data)}');
            
            // Restructure TRC10 data to match the format expected by token_detail_page
            final List<dynamic> restructuredData = [];
            if (data['data'] != null) {
              print('Found ${data['data'].length} transactions');
              for (var tx in data['data']) {
                print('Processing transaction: ${json.encode(tx)}');
                
                // Skip if not a transfer transaction
                if (tx['contractType'] != 1 && tx['contractType'] != 2) {
                  print('Skipping non-transfer transaction type: ${tx['contractType']}');
                  continue;
                }

                final contractData = tx['contractData'];
                if (contractData == null) {
                  print('No contract data found in transaction');
                  continue;
                }

                // For TRC10 token transfers (contractType = 2) or TRX transfers (contractType = 1)
                final tokenInfo = tx['contractType'] == 2 
                    ? contractData['tokenInfo'] ?? {} 
                    : tx['tokenInfo'] ?? {};

                // Skip if token abbreviation doesn't match (for non-TRX tokens)
                if (tokenAbbr != null && 
                    tokenInfo['tokenAbbr']?.toString().toUpperCase() != tokenAbbr.toUpperCase()) {
                  print('Skipping transaction for different token: ${tokenInfo['tokenAbbr']}');
                  continue;
                }

                restructuredData.add({
                  'timestamp': tx['timestamp'],
                  'ownerAddress': contractData['owner_address'],
                  'toAddress': contractData['to_address'],
                  'amount': contractData['amount']?.toString() ?? '0',
                  'tokenInfo': {
                    'tokenId': tokenInfo['tokenId'] ?? '_',
                    'tokenAbbr': tokenInfo['tokenAbbr'] ?? 'trx',
                    'tokenName': tokenInfo['tokenName'] ?? 'trx',
                    'tokenDecimal': tokenInfo['tokenDecimal'] ?? 6,
                    'tokenType': 'trc10',
                  },
                  'contractRet': tx['contractRet'] ?? 'SUCCESS',
                  'transactionId': tx['hash'],
                });
              }
            } else {
              print('No transaction data found in response');
            }
            print('Restructured ${restructuredData.length} transactions');
            
            return {
              'data': restructuredData,
              'total': data['total'] ?? restructuredData.length,
            };
          }
        } else {
          print('Failed to fetch transaction history: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to load transaction history: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching transaction history: $e');
        throw Exception('Error getting transaction history: $e');
      }
    });
  }

  // Keep the old methods for backward compatibility
  Future<Map<String, dynamic>> getTransactionHistory(
    String address, {
    int limit = 10,
    String sort = '-timestamp',
  }) async {
    return getTransactions(
      address,
      tokenType: 'trc10',
      limit: limit,
      sort: sort,
    );
  }

  Future<Map<String, dynamic>> getTrc20Transfers(
    String address, {
    String? tokenAbbr,
    int limit = 10,
    int start = 0,
    String sort = '-timestamp',
  }) async {
    return getTransactions(
      address,
      tokenType: 'trc20',
      tokenAbbr: tokenAbbr,
      limit: limit,
      start: start,
      sort: sort,
    );
  }
} 