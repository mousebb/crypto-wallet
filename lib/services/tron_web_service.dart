import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TronWebService {
  static const String _tronWebScript = '''
    <script src="https://cdn.jsdelivr.net/npm/tronweb@4.1.0/dist/TronWeb.js"></script>
    <script>
      const tronWeb = new TronWeb({
        fullHost: 'https://api.trongrid.io',
        headers: { "TRON-PRO-API-KEY": "your-api-key" }
      });

      function createAccount() {
        const account = tronWeb.createAccount();
        return {
          privateKey: account.privateKey,
          address: account.address.base58
        };
      }

      function importFromPrivateKey(privateKey) {
        const account = tronWeb.fromPrivateKey(privateKey);
        return {
          privateKey: privateKey,
          address: account.address.base58
        };
      }
    </script>
  ''';

  final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(_tronWebScript);

  Future<Map<String, dynamic>> createAccount() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('createAccount()');
      return jsonDecode(result.toString());
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> importFromPrivateKey(String privateKey) async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'importFromPrivateKey("$privateKey")'
      );
      return jsonDecode(result.toString());
    } catch (e) {
      print('Error importing account: $e');
      rethrow;
    }
  }
} 