import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';
import '../services/wallet_generator_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class ImportMethodPage extends StatefulWidget {
  const ImportMethodPage({super.key});

  @override
  State<ImportMethodPage> createState() => _ImportMethodPageState();
}

class _ImportMethodPageState extends State<ImportMethodPage> {
  final _formKey = GlobalKey<FormState>();
  final _walletNameController = TextEditingController(text: 'TRON-1');
  final _importDataController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _showLoadingDialog() {
    setState(() {
      _isLoading = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  bool _validateInputs() {
    if (_importDataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('import_method.empty_import_data'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_walletNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('import_method.empty_wallet_name'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('import_method.password_too_short'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('import_method.password_mismatch'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  bool _isMnemonic(String input) {
    // 检查是否是助记词（多个单词，用空格分隔）
    final words = input.trim().split(' ');
    return words.length > 1;
  }

  Future<void> _importWallet() async {
    if (!_validateInputs()) {
      return;
    }

    _showLoadingDialog();

    try {
      final generator = WalletGeneratorService();
      final input = _importDataController.text.trim();
      WalletData walletData;

      if (_isMnemonic(input)) {
        // Import using mnemonic
        walletData = await generator.importFromMnemonic(input);
      } else {
        // Import using private key
        walletData = await generator.importFromPrivateKey(input);
      }

      // Update wallet name
      walletData = WalletData(
        mnemonic: walletData.mnemonic,
        privateKey: walletData.privateKey,
        address: walletData.address,
        name: _walletNameController.text,
        isBackedUp: true,
      );

      // Save wallet to database
      await DatabaseService().saveWallet(
        walletData,
        _passwordController.text,
        _walletNameController.text,
      );

      if (mounted) {
        _hideLoadingDialog();
        // Navigate to home page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('import_method.import_error'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
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
        title: Text(
          'import_method.title'.tr(),
          style: AppTheme.getTextTheme(context).titleLarge,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              // TODO: Implement QR code scanning
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                decoration: AppTheme.getContainerDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _importDataController,
                      style: AppTheme.getTextTheme(context).bodyMedium,
                      decoration: AppTheme.getTextFieldDecoration(
                        context,
                        hintText: 'import_method.import_data_hint'.tr(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Text(
                'import_method.set_wallet_name'.tr(),
                style: AppTheme.getTextTheme(context).titleMedium,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                decoration: AppTheme.getContainerDecoration(context, borderRadius: 8),
                child: TextField(
                  controller: _walletNameController,
                  style: AppTheme.getTextTheme(context).bodyMedium,
                  decoration: AppTheme.getTextFieldDecoration(
                    context,
                    hintText: 'import_method.wallet_name_hint'.tr(),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Text(
                'import_method.set_password'.tr(),
                style: AppTheme.getTextTheme(context).titleMedium,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                decoration: AppTheme.getContainerDecoration(context, borderRadius: 8),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTheme.getTextTheme(context).bodyMedium,
                  decoration: AppTheme.getTextFieldDecoration(
                    context,
                    hintText: 'import_method.password_hint'.tr(),
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                decoration: AppTheme.getContainerDecoration(context, borderRadius: 8),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: AppTheme.getTextTheme(context).bodyMedium,
                  decoration: AppTheme.getTextFieldDecoration(
                    context,
                    hintText: 'import_method.confirm_password_hint'.tr(),
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'import_method.agree_terms'.tr(),
                          style: AppTheme.getTextTheme(context).bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to terms page
                          },
                          style: AppTheme.getTextButtonStyle(context).copyWith(
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                            minimumSize: MaterialStateProperty.all(Size.zero),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'import_method.terms_of_service'.tr(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              PrimaryButton(
                text: 'import_method.import_wallet'.tr(),
                onPressed: _agreedToTerms && !_isLoading ? _importWallet : null,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 