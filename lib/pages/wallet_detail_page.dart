import 'package:flutter/material.dart';
import 'package:crypto_wallet/pages/mnemonic_page.dart';
import 'package:crypto_wallet/services/wallet_service.dart';
import 'package:crypto_wallet/pages/wallet_guide_page.dart';
import 'package:crypto_wallet/main.dart';
import 'package:crypto_wallet/services/database_service.dart';
import 'package:crypto_wallet/pages/private_key_page.dart';
import 'package:crypto_wallet/widgets/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class WalletDetailPage extends StatefulWidget {
  final String address;

  const WalletDetailPage({Key? key, required this.address}) : super(key: key);

  @override
  State<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends State<WalletDetailPage> {
  String? _walletName;
  bool _isLoading = true;
  bool _isBackedUp = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      final db = await DatabaseService().database;
      final result = await db.query(
        'wallets',
        columns: ['name', 'is_backed_up'],
        where: 'address = ?',
        whereArgs: [widget.address],
      );
      
      if (mounted && result.isNotEmpty) {
        setState(() {
          _walletName = result.first['name'] as String;
          _isBackedUp = (result.first['is_backed_up'] as int) == 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading wallet data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).dialogBackgroundColor,
              title: Text(
                'wallet_detail.delete_dialog.title'.tr(),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'wallet_detail.delete_dialog.message'.tr(),
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'wallet_detail.delete_dialog.password_hint'.tr(),
                      hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.03,
                        vertical: MediaQuery.of(context).size.height * 0.01,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'wallet_detail.delete_dialog.cancel'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          print('Verifying password for wallet: ${widget.address}');
                          print('Entered password: ${passwordController.text}');
                          
                          try {
                            final isValid = await DatabaseService().verifyPassword(
                              widget.address,
                              passwordController.text,
                            );
                            print('Password verification result: $isValid');

                            if (isValid) {
                              await DatabaseService().deleteWallet(widget.address);
                              
                              // Check if there are any remaining wallets
                              final hasWallets = await DatabaseService().hasWallets();
                              
                              if (mounted) {
                                Navigator.of(context).pop(); // Close dialog
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => hasWallets 
                                      ? const HomePage() 
                                      : const WalletGuidePage(),
                                  ),
                                  (route) => false,
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('wallet_detail.delete_dialog.password_error'.tr())),
                                );
                              }
                            }
                          } catch (e) {
                            print('Error during wallet deletion: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('wallet_detail.delete_dialog.error'.tr(args: [e.toString()]))),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                  child: Text(
                    'wallet_detail.delete_dialog.confirm'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditNameDialog() async {
    final TextEditingController nameController = TextEditingController(text: _walletName);
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Text(
            'wallet_detail.edit_name.title'.tr(),
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: TextField(
            controller: nameController,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.035,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            decoration: InputDecoration(
              hintText: 'wallet_detail.edit_name.hint'.tr(),
              hintStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'wallet_detail.edit_name.cancel'.tr(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('wallet_detail.edit_name.empty_error'.tr())),
                  );
                  return;
                }
                
                try {
                  final db = await DatabaseService().database;
                  await db.update(
                    'wallets',
                    {'name': newName},
                    where: 'address = ?',
                    whereArgs: [widget.address],
                  );
                  
                  if (mounted) {
                    setState(() {
                      _walletName = newName;
                    });
                    Navigator.of(context).pop(); // Just close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('wallet_detail.edit_name.success'.tr())),
                    );
                  }
                } catch (e) {
                  print('Error updating wallet name: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('wallet_detail.edit_name.error'.tr(args: [e.toString()]))),
                    );
                  }
                }
              },
              child: Text(
                'wallet_detail.edit_name.confirm'.tr(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'wallet_detail.title'.tr(),
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).cardColor,
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Image.asset('assets/images/trx_logo.png'),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _walletName ?? 'wallet_detail.default_name'.tr(),
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showEditNameDialog,
                            child: Icon(Icons.edit, size: 16, color: Theme.of(context).iconTheme.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.address,
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.03,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: widget.address)).then((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('wallet_detail.copied'.tr(args: ['wallet_detail.wallet_address'.tr()])),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              });
                            },
                            child: Icon(Icons.copy, size: 16, color: Theme.of(context).iconTheme.color),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.backup, color: Theme.of(context).iconTheme.color),
                  title: Text('wallet_detail.backup_mnemonic'.tr(), style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  )),
                  trailing: _isBackedUp == false
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.02,
                            vertical: MediaQuery.of(context).size.height * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'wallet_detail.not_backed_up'.tr(),
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: MediaQuery.of(context).size.width * 0.03,
                            ),
                          ),
                        )
                      : null,
                  onTap: () async {
                    final walletService = WalletService();
                    try {
                      final mnemonic = await walletService.getMnemonic(widget.address);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MnemonicPage(
                            mnemonic: mnemonic,
                            walletAddress: widget.address,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('wallet_detail.mnemonic_error'.tr(args: [e.toString()]))),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock_outline, color: Theme.of(context).iconTheme.color),
                  title: Text('wallet_detail.export_private_key'.tr(), style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  )),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                  onTap: () async {
                    final walletService = WalletService();
                    try {
                      final walletData = await walletService.getCurrentWallet();
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrivateKeyPage(privateKey: walletData.privateKey),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('wallet_detail.private_key_error'.tr(args: [e.toString()]))),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.security, color: Theme.of(context).iconTheme.color),
                  title: Text('wallet_detail.permission_management'.tr(), style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  )),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                  onTap: () {
                    // TODO: Navigate to permission management page
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person_outline, color: Theme.of(context).iconTheme.color),
                  title: Text('wallet_detail.whitelist'.tr(), style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  )),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                  onTap: () {
                    // TODO: Navigate to whitelist page
                  },
                ),
                ListTile(
                  leading: Icon(Icons.fingerprint, color: Theme.of(context).iconTheme.color),
                  title: Text('wallet_detail.fingerprint_payment'.tr(), style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  )),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      // TODO: Implement fingerprint payment toggle
                    },
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.lock, color: Theme.of(context).iconTheme.color),
                  title: Text('wallet_detail.change_password'.tr(), style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  )),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                  onTap: () {
                    // TODO: Navigate to change password page
                  },
                ),
                ListTile(
                  leading: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
                  title: Text('wallet_detail.reset_password'.tr(), style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  )),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                  onTap: () {
                    // TODO: Navigate to reset password page
                  },
                ),
                // Add padding at the bottom to ensure content is not hidden behind the button
                const SizedBox(height: 80),
              ],
            ),
          ),
          // Fixed position delete button at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: PrimaryButton(
                text: 'wallet_detail.delete'.tr(),
                onPressed: () => _showDeleteConfirmationDialog(),
                type: PrimaryButtonType.delete,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 