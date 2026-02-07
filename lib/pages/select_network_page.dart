import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'create_wallet_page.dart';
import 'import_wallet_page.dart';

class SelectNetworkPage extends StatelessWidget {
  final bool isImporting;

  const SelectNetworkPage({
    super.key,
    this.isImporting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'select_network.title'.tr(),
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.06,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'select_network.search'.tr(),
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.04,
              top: MediaQuery.of(context).size.height * 0.01,
              bottom: MediaQuery.of(context).size.height * 0.01,
            ),
            child: Text(
              'select_network.single_network_wallet'.tr(),
              style: TextStyle(
                color: Colors.grey,
                fontSize: MediaQuery.of(context).size.width * 0.035,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildNetworkItem(
                  context,
                  'assets/images/btc_logo.png',
                  'select_network.networks.bitcoin'.tr(),
                  'BTC',
                  false,
                ),
                _buildNetworkItem(
                  context,
                  'assets/images/eth_logo.png',
                  'select_network.networks.ethereum'.tr(),
                  'ETH',
                  false,
                ),
                _buildNetworkItem(
                  context,
                  'assets/images/bnb_logo.png',
                  'select_network.networks.binance'.tr(),
                  'BSC',
                  false,
                ),
                _buildNetworkItem(
                  context,
                  'assets/images/trx_logo.png',
                  'select_network.networks.tron'.tr(),
                  'TRX',
                  true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => isImporting
                            ? const ImportWalletPage()
                            : const CreateWalletPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkItem(
    BuildContext context,
    String logoPath,
    String name,
    String symbol,
    bool isEnabled, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.01,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        enabled: isEnabled,
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Image.asset(logoPath),
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isEnabled
                ? Theme.of(context).textTheme.titleMedium?.color
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        subtitle: Text(
          symbol,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isEnabled
              ? Theme.of(context).iconTheme.color
              : Theme.of(context).textTheme.bodySmall?.color,
        ),
        onTap: isEnabled ? onTap : null,
      ),
    );
  }
} 