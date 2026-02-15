import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/utils/ai_operations.dart';
import 'package:yourapp/utils/file_operations.dart';
import 'package:yourapp/ui/components/alert_dialog_widget.dart';
import 'package:yourapp/ui/components/nightrider_loading.dart';

class SavedWidget extends StatefulWidget {
  final String prompt;
  final String html;
  final String? spec;

  const SavedWidget(
      {super.key, required this.prompt, required this.html, this.spec});

  @override
  State<SavedWidget> createState() => SavedWidgetState();
}

class SavedWidgetState extends State<SavedWidget> {
  late TextEditingController _controller;
  final gemini = AIOperations();
  bool _isLoading = false;
  String _loadingMessage = "Applying...";

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
      _loadingMessage = "Applying...";
    });

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
          bottomWidget: SavedWidget(
              prompt: widget.prompt, html: newHtmlCode, spec: widget.spec),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: AppTextStyles.mono,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: '> edit instructions',
                          hintStyle: AppTextStyles.mono.copyWith(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _isLoading
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NightRiderLoading(
                                  size: 14,
                                  color: AppColors.accentBlue,
                                  strokeWidth: 1.5,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _loadingMessage,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : IconButton(
                            onPressed:
                                _controller.text.isEmpty ? null : _handleSubmit,
                            icon: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _controller.text.isEmpty
                                    ? AppColors.elevated
                                    : AppColors.accentBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: _controller.text.isEmpty
                                    ? AppColors.textMuted
                                    : Colors.white,
                                size: 16,
                              ),
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                          ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          showConfirmationDialog(
                            context: context,
                            title: "Save App",
                            content: "Save this app to your collection?",
                            onConfirm: () {
                              FileOperations fo = FileOperations();
                              fo.saveHtml(widget.prompt, widget.html, context,
                                  spec: widget.spec);
                            },
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
                      const Icon(Icons.bookmark_add_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('Save',
                          style: AppTextStyles.button
                              .copyWith(color: Colors.white)),
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
