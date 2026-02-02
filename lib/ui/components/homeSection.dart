import 'package:flutter/material.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/utils/ai_operations.dart';
import 'package:yourapp/ui/components/savedWidget.dart';
import 'package:yourapp/ui/components/alertDialogWidget.dart';

class HomeComponent extends StatefulWidget {
  const HomeComponent({super.key});

  @override
  State<HomeComponent> createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent> {
  TextEditingController controller = TextEditingController();

  final gemini = AIOperations();
  double progress = 0.0;
  bool isLoading = false;
  String loadingMessage = "Processing your request...";

  final List<String> loadingMessages = [
    "Analyzing prompt...",
    "Generating content...",
    "Almost done...",
  ];

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void updateLoadingMessage() {
    if (progress < 0.25) {
      loadingMessage = loadingMessages[0];
    } else if (progress < 0.5) {
      loadingMessage = loadingMessages[1];
    } else {
      loadingMessage = loadingMessages[2];
    }
  }

  Future<void> handleSubmit() async {
    if (controller.text.isEmpty) return;

    setState(() {
      isLoading = true;
      progress = 0.1;
      updateLoadingMessage();
    });

    final finalPrompt = await gemini.getPrompt(controller.text);
    setState(() {
      progress = 0.5;
      updateLoadingMessage();
    });

    if (finalPrompt == null) {
      showErrorDialog(context, "You used a wrong prompt.");
      setState(() {
        isLoading = false;
        progress = 0.0;
      });
      return;
    }

    setState(() {
      progress = 0.75;
      updateLoadingMessage();
    });

    final htmlCode = await gemini.getCode(finalPrompt);
    setState(() {
      progress = 1.0;
      updateLoadingMessage();
    });

    String prompt = controller.text;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BrowserUI(
                html: htmlCode!,
                bottomWidget: SavedWidget(prompt: prompt, html: htmlCode),
              )),
    );
    controller.clear();
    setState(() {
      isLoading = false;
      progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: isLoading ? _buildLoadingUI() : _buildWelcomeUI(),
            ),
          ),
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.navy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 32,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "What can I help with?",
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Describe your app idea below",
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: controller.text.isNotEmpty ? AppColors.navy : AppColors.border,
            width: controller.text.isNotEmpty ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.body,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Describe your app idea...',
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                onPressed: controller.text.isEmpty || isLoading ? null : handleSubmit,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: controller.text.isEmpty
                        ? AppColors.surfaceVariant
                        : AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: controller.text.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textOnDark,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    int percentage = (progress * 100).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                value: progress,
                color: AppColors.navy,
                backgroundColor: AppColors.surfaceVariant,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$percentage%",
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          loadingMessage,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Please wait while we generate your app",
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
