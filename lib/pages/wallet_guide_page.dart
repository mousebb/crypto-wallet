import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';
import '../services/database_service.dart';
import 'wallet_create_options_page.dart';
import 'select_network_page.dart';
import 'import_wallet_page.dart';
import 'create_wallet_page.dart';

class WalletGuidePage extends StatefulWidget {
  const WalletGuidePage({super.key});

  @override
  State<WalletGuidePage> createState() => _WalletGuidePageState();
}

class _WalletGuidePageState extends State<WalletGuidePage> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _checkWallet();
  }

  Future<void> _checkWallet() async {
    final hasWallet = await _databaseService.hasWallet();
    if (!mounted) return;

    if (hasWallet) {
      // Navigate to home page if wallet exists
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Wallet image
                    Builder(
                      builder: (context) {
                        final imageWidth = MediaQuery.of(context).size.width * 0.8;
                        return Image(
                          image: const AssetImage('assets/images/wallet_guide.png'),
                          width: imageWidth,
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'wallet_guide.title'.tr(),
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.06,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      Text(
                        'wallet_guide.subtitle'.tr(),
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          color: subtitleColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                      // Wallet options
                      _buildWalletOption(
                        context,
                        icon: Icons.account_balance_wallet,
                        title: 'wallet_guide.have_wallet'.tr(),
                        subtitle: 'wallet_guide.have_wallet_subtitle'.tr(),
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ImportWalletPage(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      _buildWalletOption(
                        context,
                        icon: Icons.add_circle,
                        title: 'wallet_guide.no_wallet'.tr(),
                        subtitle: 'wallet_guide.no_wallet_subtitle'.tr(),
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateWalletPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlue = color == Colors.blue;
    final textColor = isBlue ? Colors.white : (isDark ? Colors.white : Colors.black87);
    final subtitleColor = isBlue ? Colors.grey[300] : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: MediaQuery.of(context).size.width * 0.06),
            SizedBox(width: MediaQuery.of(context).size.width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                    ),
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