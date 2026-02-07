import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';
import '../services/wallet_generator_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'mnemonic_notice_page.dart';

class CreateWalletPage extends StatefulWidget {
  const CreateWalletPage({super.key});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  final _formKey = GlobalKey<FormState>();
  final _walletNameController = TextEditingController(text: 'TRON-1');
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
    if (_walletNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('create_wallet.empty_wallet_name'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('create_wallet.empty_password'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('create_wallet.password_too_short'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('create_wallet.password_mismatch'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _createWallet() async {
    if (!_validateInputs()) {
      return;
    }

    _showLoadingDialog();

    try {
      if (mounted) {
        _hideLoadingDialog();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MnemonicNoticePage(
              password: _passwordController.text,
              walletName: _walletNameController.text,
            ),
          ),
        );
      }
    } catch (e) {
      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('create_wallet.create_error'.tr(args: [e.toString()])),
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
          'create_wallet.title'.tr(),
          style: AppTheme.getTextTheme(context).titleLarge,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'create_wallet.set_wallet_name'.tr(),
                style: AppTheme.getTextTheme(context).titleMedium,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                decoration: AppTheme.getContainerDecoration(context, borderRadius: 8),
                child: TextFormField(
                  controller: _walletNameController,
                  style: AppTheme.getTextTheme(context).bodyMedium,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'create_wallet.empty_wallet_name'.tr();
                    }
                    return null;
                  },
                  decoration: AppTheme.getTextFieldDecoration(
                    context,
                    hintText: 'create_wallet.wallet_name_hint'.tr(),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Text(
                'create_wallet.set_password'.tr(),
                style: AppTheme.getTextTheme(context).titleMedium,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                decoration: AppTheme.getContainerDecoration(context, borderRadius: 8),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTheme.getTextTheme(context).bodyMedium,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'create_wallet.empty_password'.tr();
                    }
                    if (value.length < 8) {
                      return 'create_wallet.password_too_short'.tr();
                    }
                    return null;
                  },
                  decoration: AppTheme.getTextFieldDecoration(
                    context,
                    hintText: 'create_wallet.password_hint'.tr(),
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
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                decoration: AppTheme.getContainerDecoration(context, borderRadius: 8),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: AppTheme.getTextTheme(context).bodyMedium,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'create_wallet.empty_confirm_password'.tr();
                    }
                    if (value != _passwordController.text) {
                      return 'create_wallet.password_mismatch'.tr();
                    }
                    return null;
                  },
                  decoration: AppTheme.getTextFieldDecoration(
                    context,
                    hintText: 'create_wallet.confirm_password_hint'.tr(),
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
              const SizedBox(height: 8),
              Text(
                'create_wallet.password_description'.tr(),
                style: AppTheme.getTextTheme(context).bodySmall,
              ),
              const SizedBox(height: 24),
              Row(
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
                    child: Text(
                      'create_wallet.terms_agreement'.tr(),
                      style: AppTheme.getTextTheme(context).bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'create_wallet.create_button'.tr(),
                onPressed: _agreedToTerms && !_isLoading ? _createWallet : null,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 