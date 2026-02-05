import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/home.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/ui/components/savedWidget.dart';
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
  bool _isLoading = true;
  bool _isDeleting = false;

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
          setState(() {
            _htmlContent = file.readAsStringSync();
            _prompt = data["prompt"];
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
        // Code viewer
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF282C34), // atom-one-dark background
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
          ),
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
}
