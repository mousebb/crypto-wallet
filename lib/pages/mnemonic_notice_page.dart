import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'mnemonic_display_page.dart';
import '../services/wallet_generator_service.dart';
import '../services/database_service.dart';

class MnemonicNoticePage extends StatefulWidget {
  final String password;
  final String walletName;

  const MnemonicNoticePage({
    super.key,
    required this.password,
    required this.walletName,
  });

  @override
  State<MnemonicNoticePage> createState() => _MnemonicNoticePageState();
}

class _MnemonicNoticePageState extends State<MnemonicNoticePage> {
  bool _understoodLoss = false;
  bool _understoodSharing = false;

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onGenerateMnemonic(BuildContext context) async {
    _showLoadingDialog(context);

    try {
      // Generate wallet
      final generator = WalletGeneratorService();
      final walletData = await generator.generateWallet();
      
      // Save wallet
      await DatabaseService().saveWallet(walletData, widget.password, widget.walletName);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MnemonicDisplayPage(
              address: walletData.address,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('mnemonic_notice.generate_error'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canProceed = _understoodLoss && _understoodSharing;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'mnemonic_notice.title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: MediaQuery.of(context).size.height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mnemonic_notice.warning_title'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Text(
                  'mnemonic_notice.warning_description'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildWarningItem(
                  context,
                  icon: Icons.security,
                  title: 'mnemonic_notice.warning_item1_title'.tr(),
                  description: 'mnemonic_notice.warning_item1_description'.tr(),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                _buildWarningItem(
                  context,
                  icon: Icons.warning,
                  title: 'mnemonic_notice.warning_item2_title'.tr(),
                  description: 'mnemonic_notice.warning_item2_description'.tr(),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                _buildWarningItem(
                  context,
                  icon: Icons.backup,
                  title: 'mnemonic_notice.warning_item3_title'.tr(),
                  description: 'mnemonic_notice.warning_item3_description'.tr(),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                CheckboxListTile(
                  value: _understoodLoss,
                  onChanged: (value) {
                    setState(() {
                      _understoodLoss = value ?? false;
                    });
                  },
                  title: Text(
                    'mnemonic_notice.understand_loss'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _understoodSharing,
                  onChanged: (value) {
                    setState(() {
                      _understoodSharing = value ?? false;
                    });
                  },
                  title: Text(
                    'mnemonic_notice.understand_sharing'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canProceed ? () => _onGenerateMnemonic(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canProceed ? Theme.of(context).primaryColor : Colors.grey[800],
                      disabledBackgroundColor: Colors.grey[800],
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.018,
                      ),
                      elevation: canProceed ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'mnemonic_notice.next_button'.tr(),
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: canProceed ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 