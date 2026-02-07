import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/wallet_generator_service.dart';
import '../services/database_service.dart';

class MnemonicDisplayPage extends StatefulWidget {
  final String address;

  const MnemonicDisplayPage({
    super.key,
    required this.address,
  });

  @override
  State<MnemonicDisplayPage> createState() => _MnemonicDisplayPageState();
}

class _MnemonicDisplayPageState extends State<MnemonicDisplayPage> {
  WalletData? _walletData;
  bool _isLoading = true;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    try {
      print('Loading wallet data...');
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> wallets = await db.query(
        'wallets',
        where: 'address = ?',
        whereArgs: [widget.address],
      );
      
      if (wallets.isEmpty) {
        throw Exception('Wallet not found');
      }

      final wallet = wallets.first;
      setState(() {
        _walletData = WalletData(
          mnemonic: wallet['mnemonic'],
          privateKey: wallet['private_key'],
          address: wallet['address'],
          name: wallet['name'],
          isBackedUp: wallet['is_backed_up'] == 1,
        );
        _isLoading = false;
      });
      print('Wallet data loaded successfully');
    } catch (e) {
      print('Error loading wallet data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载钱包数据失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBackupSkipDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'mnemonic_display.skip_dialog.title'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'mnemonic_display.skip_dialog.message'.tr(),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'mnemonic_display.skip_dialog.skip'.tr(),
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'mnemonic_display.skip_dialog.backup'.tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCopyableText(String label, String value, {bool isPrivateKey = false}) {
    String displayValue = value;
    if (isPrivateKey && value.length > 8) {
      displayValue = '${value.substring(0, 4)}****${value.substring(value.length - 4)}';
    }

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.008,
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.035),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.008),
          Row(
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.blue),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value)).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('mnemonic_display.copied'.tr(args: [label])),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_walletData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('mnemonic_display.error'.tr()),
              ElevatedButton(
                onPressed: _loadWalletData,
                child: Text('mnemonic_display.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'mnemonic_display.title'.tr(),
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).dialogBackgroundColor,
                title: Text(
                  'mnemonic_display.exit_dialog.title'.tr(),
                  style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
                ),
                content: Text(
                  'mnemonic_display.exit_dialog.message'.tr(),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('mnemonic_display.exit_dialog.cancel'.tr()),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text('mnemonic_display.exit_dialog.confirm'.tr()),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'mnemonic_display.instruction'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: _walletData!.mnemonic.split(' ').length,
                  itemBuilder: (context, index) {
                    final words = _walletData!.mnemonic.split(' ');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              words[index],
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: _walletData!.mnemonic,
                    )).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('mnemonic_display.copied'.tr(args: ['mnemonic_display.mnemonic'.tr()])),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    });
                  },
                  child: Text(
                    'mnemonic_display.copy_mnemonic'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
              _buildCopyableText('mnemonic_display.wallet_address'.tr(), _walletData!.address),
              _buildCopyableText(
                'mnemonic_display.private_key'.tr(),
                _walletData!.privateKey,
                isPrivateKey: true,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              _buildBottomButtons(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
              Center(
                child: TextButton(
                  onPressed: _showBackupSkipDialog,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.008,
                    ),
                  ),
                  child: Text(
                    'mnemonic_display.backup_later'.tr(),
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await _databaseService.updateBackupStatus(widget.address, true);
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('mnemonic_display.backup_error'.tr(args: [e.toString()])),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'mnemonic_display.backup_complete'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 