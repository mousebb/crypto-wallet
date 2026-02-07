import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import 'package:easy_localization/easy_localization.dart';

class MnemonicPage extends StatefulWidget {
  final String mnemonic;
  final String? walletAddress;

  const MnemonicPage({
    super.key,
    required this.mnemonic,
    this.walletAddress,
  });

  @override
  State<MnemonicPage> createState() => _MnemonicPageState();
}

class _MnemonicPageState extends State<MnemonicPage> {
  bool _isVisible = false;
  final DatabaseService _databaseService = DatabaseService();

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.mnemonic));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('mnemonic_page.copied'.tr())),
    );
  }

  Future<void> _confirmBackup() async {
    if (widget.walletAddress != null) {
      try {
        await _databaseService.updateWalletBackupStatus(widget.walletAddress!, true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('mnemonic_page.backup_updated'.tr())),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('mnemonic_page.backup_error'.tr(args: [e.toString()]))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'mnemonic_page.title'.tr(),
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'mnemonic_page.instruction'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              'mnemonic_page.warning'.tr(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (!_isVisible)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 48,
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isVisible = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            child: Text(
                              'mnemonic_page.show_mnemonic'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.mnemonic
                              .split(' ')
                              .asMap()
                              .entries
                              .map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${entry.key + 1}. ${entry.value}',
                                style: Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).textTheme.bodyMedium
                                    : TextStyle(
                                        color: Colors.black87,
                                        fontSize: MediaQuery.of(context).size.width * 0.035,
                                        fontWeight: FontWeight.w500,
                                      ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        OutlinedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: Icon(Icons.copy, color: Theme.of(context).primaryColor),
                          label: Text(
                            'mnemonic_page.copy_mnemonic'.tr(),
                            style: TextStyle(color: Theme.of(context).primaryColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        if (widget.walletAddress != null)
                          ElevatedButton(
                            onPressed: _confirmBackup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(
                              'mnemonic_page.confirm_backup'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 