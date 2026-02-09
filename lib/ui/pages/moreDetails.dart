import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/home.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/ui/components/savedWidget.dart';
import 'package:yourapp/utils/file_operations.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:yourapp/ui/components/alertDialogWidget.dart';

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
          // Load spec file if it exists
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
    // Also delete spec file if it exists
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
          'Code Details',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _htmlContent == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.navy,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading code...",
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "File not found",
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "The requested file could not be loaded",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prompt',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _prompt ?? "No prompt available",
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Spec/Code toggle (only show if spec exists)
        if (_specContent != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  label: 'Spec',
                  icon: Icons.description_outlined,
                  isActive: _showSpec,
                  onTap: () => setState(() => _showSpec = true),
                ),
                const SizedBox(width: 8),
                _buildToggleButton(
                  label: 'Code',
                  icon: Icons.code_rounded,
                  isActive: !_showSpec,
                  onTap: () => setState(() => _showSpec = false),
                ),
              ],
            ),
          ),
        ],
        // Content viewer
        Expanded(
          child: _showSpec && _specContent != null
              ? _buildSpecViewer()
              : _buildCodeViewer(),
        ),
        // Action buttons
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.textOnDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: AppColors.textOnDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.textOnDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isDeleting
                        ? null
                        : () {
                            showConfirmationDialog(
                              context: context,
                              title: "Delete App",
                              content: "Are you sure you want to delete this app? This action cannot be undone.",
                              onConfirm: _deleteHtml,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDeleting ? AppColors.surfaceVariant : AppColors.errorLight,
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isDeleting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppColors.error,
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

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.navy : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.textOnDark : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? AppColors.textOnDark : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecViewer() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: SingleChildScrollView(
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
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              line.substring(2),
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textOnDark,
                fontSize: 18,
              ),
            ),
          );
        } else if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 8),
            child: Text(
              line.substring(3),
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textOnDark,
                fontSize: 15,
              ),
            ),
          );
        } else if (line.startsWith('- ') || line.startsWith('• ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: AppColors.slateMuted, fontSize: 14)),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(color: AppColors.textOnDark.withOpacity(0.85), fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        } else if (line.trim().isEmpty) {
          return const SizedBox(height: 6);
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: TextStyle(color: AppColors.textOnDark.withOpacity(0.9), fontSize: 13, height: 1.5),
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildCodeViewer() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF282C34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: SingleChildScrollView(
          child: HighlightView(
            cleanHtml(_htmlContent!),
            language: 'html',
            theme: atomOneDarkTheme,
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
