import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/tron_scan_service.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';

class TransferPage extends StatefulWidget {
  final String symbol;
  final double quantity;

  const TransferPage({
    super.key,
    required this.symbol,
    required this.quantity,
  });

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  double _estimatedFee = 0.0;
  bool _isValidInput = false;

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_validateInput);
    _amountController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _addressController.removeListener(_validateInput);
    _amountController.removeListener(_validateInput);
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final hasAddress = _addressController.text.trim().isNotEmpty;
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    final hasValidAmount = amount > 0 && amount <= widget.quantity;

    setState(() {
      _isValidInput = hasAddress && hasValidAmount;
    });

    _calculateNetworkFee();
  }

  Future<void> _calculateNetworkFee() async {
    if (_addressController.text.isEmpty || _amountController.text.isEmpty) {
      setState(() {
        _estimatedFee = 0.0;
      });
      return;
    }

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) {
        setState(() {
          _estimatedFee = 0.0;
        });
        return;
      }

      // TODO: 调用实际的网络费用计算API
      // 这里暂时使用模拟数据
      setState(() {
        _estimatedFee = 0.01; // 实际应该根据API返回值设置
      });
    } catch (e) {
      print('Error calculating network fee: $e');
      setState(() {
        _estimatedFee = 0.0;
      });
    }
  }

  Future<void> _scanQRCode() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                width: MediaQuery.of(context).size.width,
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null) {
                        // 关闭扫描页面
                        Navigator.pop(context);
                        
                        // 处理扫描结果
                        setState(() {
                          _addressController.text = code;
                        });
                        
                        // 显示成功消息
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('transfer.address_scanned'.tr())),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'transfer.qr_scan_hint'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        title: Text(
          'transfer.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'transfer.receive_address'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.getContainerDecoration(context),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      maxLines: null,
                      maxLength: 100,
                      // style: TextStyle(
                      //   fontSize: MediaQuery.of(context).size.width * 0.035,
                      // ),
                      decoration: InputDecoration(
                        hintText: 'transfer.address_hint'.tr(),
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.04,
                          vertical: MediaQuery.of(context).size.height * 0.015,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanQRCode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'transfer.amount'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'transfer.available'.tr(args: [widget.quantity.toStringAsFixed(4), widget.symbol]),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.getContainerDecoration(context),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: AppTheme.getTextFieldDecoration(
                        context,
                        hintText: 'transfer.amount_hint'.tr(args: [widget.symbol]),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _amountController.text = widget.quantity.toString();
                    },
                    style: AppTheme.getTextButtonStyle(context),
                    child: Text('transfer.all'.tr()),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Row(
              children: [
                Text(
                  'transfer.network_fee'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                Icon(
                  Icons.help_outline,
                  size: MediaQuery.of(context).size.width * 0.04,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Container(
              decoration: AppTheme.getContainerDecoration(context),
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'transfer.estimated'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _estimatedFee.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValidInput
                    ? () {
                        // TODO: 实现转账功能
                      }
                    : null,
                style: AppTheme.getPrimaryButtonStyle(context),
                child: Text(
                  'transfer.confirm'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 