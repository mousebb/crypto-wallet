import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'import_method_page.dart';

class ImportWalletPage extends StatelessWidget {
  const ImportWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'import_wallet.title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildImportOption(
              context,
              icon: Icons.description_outlined,
              iconColor: Colors.blue,
              title: 'import_wallet.mnemonic_import'.tr(),
              subtitle: 'import_wallet.mnemonic_import_subtitle'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportMethodPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildImportOption(
              context,
              icon: Icons.key_outlined,
              iconColor: Colors.blue,
              title: 'import_wallet.private_key_import'.tr(),
              subtitle: 'import_wallet.private_key_import_subtitle'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportMethodPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildImportOption(
              context,
              icon: Icons.lock_outline,
              iconColor: Colors.green,
              title: 'import_wallet.cold_wallet'.tr(),
              subtitle: 'import_wallet.cold_wallet_subtitle'.tr(),
              onTap: () {
                // TODO: Navigate to cold wallet page
              },
            ),
            const SizedBox(height: 16),
            _buildImportOption(
              context,
              icon: Icons.visibility_outlined,
              iconColor: Colors.green,
              title: 'import_wallet.watch_wallet'.tr(),
              subtitle: 'import_wallet.watch_wallet_subtitle'.tr(),
              onTap: () {
                // TODO: Navigate to watch wallet page
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
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
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
} 