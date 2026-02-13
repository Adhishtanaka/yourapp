import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourapp/ui/components/alertDialogWidget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  bool _isClearingRecords = false;
  bool _isResetting = false;

  Future<void> clearAllRecords() async {
    setState(() {
      _isClearingRecords = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    if (dir.existsSync()) {
      dir.listSync().forEach((file) {
        if (file is File) {
          file.deleteSync();
        }
      });
    }

    setState(() {
      _isClearingRecords = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Records cleared", style: AppTextStyles.caption.copyWith(color: Colors.white)),
        backgroundColor: AppColors.accentBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> clearAllData() async {
    setState(() {
      _isResetting = true;
    });

    await clearAllRecords();
    await storage.delete(key: "api_key");

    setState(() {
      _isResetting = false;
    });

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: AppTextStyles.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('API'),
            const SizedBox(height: 6),
            _buildApiCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('Data'),
            const SizedBox(height: 6),
            _buildDataManagementCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('About'),
            const SizedBox(height: 6),
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.monoSmall.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildApiCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showApiKeyDialog(context),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.key_rounded,
                    color: AppColors.accentBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gemini API Key',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          _buildDataOption(
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.textSecondary,
            title: 'Clear Records',
            onTap: _isClearingRecords
                ? null
                : () {
                    showConfirmationDialog(
                      context: context,
                      title: "Clear Records",
                      content: "Remove all saved records? This cannot be undone.",
                      onConfirm: clearAllRecords,
                    );
                  },
            isLoading: _isClearingRecords,
          ),
          const Divider(height: 1, color: AppColors.border, indent: 58),
          _buildDataOption(
            icon: Icons.delete_forever_rounded,
            iconColor: AppColors.error,
            title: 'Reset App',
            onTap: _isResetting
                ? null
                : () {
                    showConfirmationDialog(
                      context: context,
                      title: "Reset App",
                      content: "Delete all data and close app?",
                      onConfirm: clearAllData,
                    );
                  },
            isDestructive: true,
            isLoading: _isResetting,
          ),
        ],
      ),
    );
  }

  Widget _buildDataOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback? onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.errorLight
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: iconColor,
                          ),
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentBlue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('yourapp', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              Text('v1.0.0', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const Spacer(),
          Text(
            'adhishtanaka',
            style: AppTextStyles.monoSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
