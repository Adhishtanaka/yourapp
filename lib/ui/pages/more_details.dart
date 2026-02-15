import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/home.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/ui/components/saved_widget.dart';
import 'package:yourapp/utils/file_operations.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:yourapp/ui/components/alert_dialog_widget.dart';

class MoreDetailsScreen extends StatefulWidget {
  final String path;

  const MoreDetailsScreen({super.key, required this.path});

  @override
  State<MoreDetailsScreen> createState() => _MoreDetailsScreenState();
}

class _MoreDetailsScreenState extends State<MoreDetailsScreen> {
  String? _htmlContent;
  String? _prompt;
  String? _specContent;
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _showSpec = false;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList("saved_html") ?? [];

    for (String item in savedList) {
      Map<String, dynamic> data = _parseData(item);
      if (data["path"] == widget.path) {
        File file = File(data["path"]);
        if (await file.exists()) {
          final fo = FileOperations();
          final spec = await fo.loadSpec(data["path"]);

          setState(() {
            _htmlContent = file.readAsStringSync();
            _prompt = data["prompt"];
            _specContent = spec;
            _isLoading = false;
          });
        }
        break;
      }
    }

    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _parseData(String data) {
    data = data.replaceAll("{", "").replaceAll("}", "");
    Map<String, String> map = {};
    for (String pair in data.split(", ")) {
      List<String> keyValue = pair.split(": ");
      if (keyValue.length == 2) {
        map[keyValue[0]] = keyValue[1];
      }
    }
    return map;
  }

  Future<void> _deleteHtml() async {
    setState(() {
      _isDeleting = true;
    });

    File file = File(widget.path);
    if (await file.exists()) {
      await file.delete();
    }
    final specPath = widget.path.replaceAll('.html', '.spec.txt');
    File specFile = File(specPath);
    if (await specFile.exists()) {
      await specFile.delete();
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList("saved_html") ?? [];
    savedList.removeWhere((item) => item.contains(widget.path.split('/').last));
    await prefs.setStringList("saved_html", savedList);

    setState(() {
      _isDeleting = false;
    });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  String cleanHtml(String html) {
    return html.replaceAll('```html', '').replaceAll('```', '').trim();
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
        title: Text('Details', style: AppTextStyles.h3),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _htmlContent == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppColors.accentBlue,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 24,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "File not found",
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Prompt header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Text(
            _prompt ?? "Untitled",
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Spec/Code toggle (tab-style)
        if (_specContent != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildTab(
                  label: 'spec.md',
                  isActive: _showSpec,
                  onTap: () => setState(() => _showSpec = true),
                ),
                const SizedBox(width: 16),
                _buildTab(
                  label: 'index.html',
                  isActive: !_showSpec,
                  onTap: () => setState(() => _showSpec = false),
                ),
              ],
            ),
          ),
        // Content viewer
        Expanded(
          child: _showSpec && _specContent != null
              ? _buildSpecViewer()
              : _buildCodeViewer(),
        ),
        // Action buttons
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrowserUI(
                              html: _htmlContent!,
                              bottomWidget: SavedWidget(
                                prompt: _prompt!,
                                html: _htmlContent!,
                                spec: _specContent,
                              ),
                            ),
                          ),
                        );
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: AppTextStyles.button
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      onPressed: _isDeleting
                          ? null
                          : () {
                              showConfirmationDialog(
                                context: context,
                                title: "Delete",
                                content: "Delete this app permanently?",
                                onConfirm: _deleteHtml,
                              );
                            },
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.error,
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.accentBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.monoSmall.copyWith(
            color: isActive ? AppColors.accentBlue : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecViewer() {
    return Container(
      margin: const EdgeInsets.all(0),
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: _buildFormattedSpec(_specContent!),
      ),
    );
  }

  Widget _buildFormattedSpec(String spec) {
    final lines = spec.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text(
              line.substring(2),
              style: AppTextStyles.mono.copyWith(
                color: AppColors.accentBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        } else if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4, top: 8),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 14,
                  color: AppColors.accentBlue,
                  margin: const EdgeInsets.only(right: 8),
                ),
                Expanded(
                  child: Text(
                    line.substring(3),
                    style: AppTextStyles.mono.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (line.startsWith('- ') || line.startsWith('• ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('·',
                    style: AppTextStyles.monoSmall
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: AppTextStyles.monoSmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (line.trim().isEmpty) {
          return const SizedBox(height: 4);
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              line,
              style: AppTextStyles.monoSmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildCodeViewer() {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          child: HighlightView(
            cleanHtml(_htmlContent!),
            language: 'html',
            theme: atomOneDarkTheme,
            padding: const EdgeInsets.all(12),
            textStyle: AppTextStyles.monoSmall.copyWith(
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
