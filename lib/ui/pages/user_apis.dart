import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourapp/ui/components/alert_dialog_widget.dart';

class UserApisPage extends StatefulWidget {
  const UserApisPage({super.key});

  @override
  State<UserApisPage> createState() => _UserApisPageState();
}

class _UserApisPageState extends State<UserApisPage> {
  List<Map<String, String>> _userApis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserApis();
  }

  Future<void> _loadUserApis() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedApis = prefs.getString('user_apis');

    if (savedApis != null) {
      try {
        List<dynamic> decoded = json.decode(savedApis);
        _userApis = decoded.map((e) => Map<String, String>.from(e)).toList();
      } catch (e) {
        _userApis = [];
      }
    } else {
      _userApis = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveUserApis() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_apis', json.encode(_userApis));
  }

  void _showAddApiDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add API', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              _buildApiTextField(
                controller: nameController,
                label: 'Name',
                hint: 'e.g., Weather API',
              ),
              const SizedBox(height: 8),
              _buildApiTextField(
                controller: urlController,
                label: 'Base URL',
                hint: 'https://api.example.com',
              ),
              const SizedBox(height: 8),
              _buildApiTextField(
                controller: keyController,
                label: 'API Key (optional)',
                hint: 'Your API key',
                isObscured: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text('Cancel', style: AppTextStyles.button),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final url = urlController.text.trim();
                        final key = keyController.text.trim();

                        if (name.isNotEmpty && url.isNotEmpty) {
                          setState(() {
                            _userApis.add({
                              'name': name,
                              'url': url,
                              'key': key,
                            });
                          });
                          _saveUserApis();
                          Navigator.pop(context);
                          HapticFeedback.mediumImpact();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: Text('Add',
                          style: AppTextStyles.button
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isObscured = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.monoSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscured,
            style: AppTextStyles.mono,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.mono.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  void _deleteApi(int index) {
    showConfirmationDialog(
      context: context,
      title: "Delete API",
      content: "Remove this API from your saved list?",
      onConfirm: () {
        setState(() {
          _userApis.removeAt(index);
        });
        _saveUserApis();
        HapticFeedback.mediumImpact();
      },
    );
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
        title: Text('User APIs', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: _showAddApiDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentBlue,
              ),
            )
          : _userApis.isEmpty
              ? _buildEmptyState()
              : _buildApiList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.api_rounded,
              size: 24,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No APIs added',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showAddApiDialog,
            child: Text(
              'Add API',
              style: AppTextStyles.button.copyWith(color: AppColors.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _userApis.length,
      itemBuilder: (context, index) {
        final api = _userApis[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                Clipboard.setData(ClipboardData(text: api['url'] ?? ''));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'URL copied',
                      style:
                          AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                    backgroundColor: AppColors.accentBlue,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    margin: const EdgeInsets.all(12),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                        Icons.link_rounded,
                        color: AppColors.accentBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            api['name'] ?? 'Unnamed API',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            api['url'] ?? '',
                            style: AppTextStyles.monoSmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (api['key']?.isNotEmpty ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'KEY',
                          style: AppTextStyles.monoSmall.copyWith(
                            color: AppColors.success,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteApi(index),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
