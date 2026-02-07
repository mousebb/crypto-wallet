import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/theme_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, size: MediaQuery.of(context).size.width * 0.06, color: iconColor ?? Theme.of(context).iconTheme.color),
      title: Text(title),
      trailing: trailing ?? Icon(Icons.chevron_right, size: MediaQuery.of(context).size.width * 0.06, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    final List<Map<String, String>> languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'zh', 'name': '简体中文'},
      {'code': 'ja', 'name': '日本語'},
      {'code': 'ko', 'name': '한국어'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'ru', 'name': 'Русский'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('profile.select_language'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];
                final currentLocale = context.locale.languageCode;
                final name = language['name'] ?? 'English';
                final code = language['code'] ?? 'en';
                
                return ListTile(
                  title: Text(name),
                  trailing: code == currentLocale
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    context.setLocale(Locale(code));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'profile.language_selected'.tr(args: [name]),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('profile.title'.tr()),
        actions: [
          IconButton(
            icon: Icon(
              themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: MediaQuery.of(context).size.width * 0.06,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              themeService.toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              size: MediaQuery.of(context).size.width * 0.06,
            ),
            onPressed: () {
              // TODO: 实现通知功能
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'profile.asset_overview'.tr(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.account_balance,
            title: 'profile.manage_wallet'.tr(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.history,
            title: 'profile.transaction_history'.tr(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.explore,
            title: 'profile.experience_zone'.tr(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.language,
            title: 'profile.language'.tr(),
            onTap: () => _showLanguageSelectionDialog(context),
          ),
        ],
      ),
    );
  }
} 