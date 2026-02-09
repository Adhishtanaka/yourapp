import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/utils/ai_operations.dart';
import 'package:yourapp/utils/file_operations.dart';
import 'package:yourapp/ui/components/alertDialogWidget.dart';

class SavedWidget extends StatefulWidget {
  final String prompt;
  final String html;
  final String? spec;

  const SavedWidget({super.key, required this.prompt, required this.html, this.spec});

  @override
  _SavedWidgetState createState() => _SavedWidgetState();
}

class _SavedWidgetState extends State<SavedWidget> {
  late TextEditingController _controller;
  final gemini = AIOperations();
  bool _isLoading = false;
  String _loadingMessage = "Applying changes...";

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_controller.text.isEmpty) return;
    
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
      _loadingMessage = "Applying changes...";
    });
    
    // Rotate messages
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() {
          _loadingMessage = "Almost done...";
        });
      }
    });
    
    final newHtmlCode = await gemini.editCode(widget.html, _controller.text);
    _controller.clear();
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrowserUI(
          html: newHtmlCode!,
          bottomWidget: SavedWidget(prompt: widget.prompt, html: newHtmlCode, spec: widget.spec),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit input field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: AppTextStyles.body,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'Describe changes to make...',
                          hintStyle: AppTextStyles.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isLoading
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.navy.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _loadingMessage,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : IconButton(
                            onPressed: _controller.text.isEmpty ? null : _handleSubmit,
                            icon: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _controller.text.isEmpty
                                    ? AppColors.surfaceVariant
                                    : AppColors.navy,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: _controller.text.isEmpty
                                    ? AppColors.textMuted
                                    : AppColors.textOnDark,
                                size: 18,
                              ),
                            ),
                          ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          showConfirmationDialog(
                            context: context,
                            title: "Save App",
                            content: "Do you want to save this app to your collection?",
                            onConfirm: () {
                              FileOperations fo = FileOperations();
                              fo.saveHtml(widget.prompt, widget.html, context, spec: widget.spec);
                            },
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
                        Icons.bookmark_add_outlined,
                        size: 20,
                        color: AppColors.textOnDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save to Collection',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
