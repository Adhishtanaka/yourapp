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
        content: Text("All records cleared successfully"),
        backgroundColor: AppColors.navy,
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
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('API Configuration'),
            const SizedBox(height: 12),
            _buildApiCard(),
            const SizedBox(height: 28),
            _buildSectionTitle('Data Management'),
            const SizedBox(height: 12),
            _buildDataManagementCard(),
            const SizedBox(height: 28),
            _buildSectionTitle('About'),
            const SizedBox(height: 12),
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.label.copyWith(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildApiCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showApiKeyDialog(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.key_rounded,
                    color: AppColors.navy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemini API Key',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure your API key for AI features',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 22,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          _buildDataOption(
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.textSecondary,
            title: 'Clear All Records',
            subtitle: 'Remove all saved HTML files',
            onTap: _isClearingRecords
                ? null
                : () {
                    showConfirmationDialog(
                      context: context,
                      title: "Clear Records",
                      content: "Are you sure you want to clear all saved records? This action cannot be undone.",
                      onConfirm: clearAllRecords,
                    );
                  },
            isLoading: _isClearingRecords,
          ),
          Divider(
            height: 1,
            color: AppColors.border,
            indent: 74,
          ),
          _buildDataOption(
            icon: Icons.delete_forever_rounded,
            iconColor: AppColors.error,
            title: 'Reset App',
            subtitle: 'Clear all data including API key',
            onTap: _isResetting
                ? null
                : () {
                    showConfirmationDialog(
                      context: context,
                      title: "Reset App",
                      content: "This will delete all data and close the app. Are you sure?",
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
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.errorLight
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      )
                    : Icon(
                        icon,
                        color: iconColor,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDestructive ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 22,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.textOnDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'yourapp',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Made by Adhishtanaka',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
