import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'create_wallet_page.dart';

class WalletCreateOptionsPage extends StatelessWidget {
  const WalletCreateOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'wallet_create_options.title'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          children: [
            _buildOptionItem(
              context,
              icon: Icons.account_balance_wallet,
              iconColor: Colors.blue,
              iconBackgroundColor: Colors.blue.withOpacity(0.2),
              title: 'wallet_create_options.create_wallet'.tr(),
              subtitle: 'wallet_create_options.create_wallet_subtitle'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateWalletPage(),
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            _buildOptionItem(
              context,
              icon: Icons.lock_outline,
              iconColor: Colors.green,
              iconBackgroundColor: Colors.green.withOpacity(0.2),
              title: 'wallet_create_options.cold_wallet'.tr(),
              subtitle: 'wallet_create_options.cold_wallet_subtitle'.tr(),
              onTap: () {
                // TODO: Navigate to cold wallet page
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            _buildOptionItem(
              context,
              icon: Icons.visibility_outlined,
              iconColor: Colors.green,
              iconBackgroundColor: Colors.green.withOpacity(0.2),
              title: 'wallet_create_options.watch_wallet'.tr(),
              subtitle: 'wallet_create_options.watch_wallet_subtitle'.tr(),
              onTap: () {
                // TODO: Navigate to watch wallet page
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: MediaQuery.of(context).size.width * 0.06,
                color: iconColor,
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
} 