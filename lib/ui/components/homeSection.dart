import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomeComponentState extends State<HomeComponent>
    with SingleTickerProviderStateMixin {
  TextEditingController controller = TextEditingController();

  final gemini = AIOperations();
  double progress = 0.0;
  bool isLoading = false;
  String loadingMessage = "Processing your request...";
  String currentTip = "";
  Timer? _messageTimer;
  Timer? _progressTimer;
  late AnimationController _pulseController;
  int _messageIndex = 0;

  final List<String> loadingMessages = [
    "Understanding your idea...",
    "Designing the interface...",
    "Creating components...",
    "Building features...",
    "Optimizing for mobile...",
    "Adding final touches...",
    "Almost ready...",
  ];

  final List<String> loadingTips = [
    "💡 Tip: Be specific about colors and layout",
    "✨ Your app will be fully responsive",
    "🎨 Using Material Design principles",
    "📱 Optimized for mobile devices",
    "⚡ All features will be functional",
    "🔧 No mock data - everything works!",
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _progressTimer?.cancel();
    _pulseController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _startLoadingAnimations() {
    _messageIndex = 0;
    currentTip = loadingTips[0];

    // Rotate messages every 4 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !isLoading) {
        timer.cancel();
        return;
      }
      setState(() {
        _messageIndex = (_messageIndex + 1) % loadingMessages.length;
        loadingMessage = loadingMessages[_messageIndex];
        currentTip = loadingTips[_messageIndex % loadingTips.length];
      });
    });

    // Smooth progress animation
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !isLoading) {
        timer.cancel();
        return;
      }
      // Gradually increase progress but cap at certain points
      if (progress < 0.45) {
        setState(() {
          progress += 0.02;
        });
      } else if (progress >= 0.5 && progress < 0.85) {
        setState(() {
          progress += 0.015;
        });
      }
    });
  }

  void _stopLoadingAnimations() {
    _messageTimer?.cancel();
    _progressTimer?.cancel();
  }

  Future<void> handleSubmit() async {
    if (controller.text.isEmpty) return;

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      progress = 0.05;
      loadingMessage = loadingMessages[0];
    });

    _startLoadingAnimations();

    final finalPrompt = await gemini.getPrompt(controller.text);

    if (!mounted) return;

    setState(() {
      progress = 0.5;
      loadingMessage = "Generating your app...";
    });

    if (finalPrompt == null) {
      _stopLoadingAnimations();
      showErrorDialog(context, "Please describe a valid app idea.");
      setState(() {
        isLoading = false;
        progress = 0.0;
      });
      return;
    }

    final htmlCode = await gemini.getCode(finalPrompt);

    if (!mounted) return;

    _stopLoadingAnimations();

    setState(() {
      progress = 1.0;
      loadingMessage = "Done!";
    });

    // Brief pause to show completion
    await Future.delayed(const Duration(milliseconds: 300));

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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, AppColors.navyLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              "What would you like\nto build today?",
              textAlign: TextAlign.center,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Describe your app idea and I'll create it for you",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            _buildSuggestionChips(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      {"icon": Icons.check_circle_outline, "text": "Todo List App"},
      {"icon": Icons.calculate_outlined, "text": "Calculator"},
      {"icon": Icons.timer_outlined, "text": "Pomodoro Timer"},
      {"icon": Icons.note_outlined, "text": "Notes App"},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions.map((suggestion) {
        return InkWell(
          onTap: () {
            controller.text = suggestion["text"] as String;
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  suggestion["icon"] as IconData,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  suggestion["text"] as String,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputSection() {
    final hasText = controller.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasText ? AppColors.navy : Colors.transparent,
              width: hasText ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: AppTextStyles.body,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: hasText && !isLoading ? handleSubmit : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasText && !isLoading
                          ? AppColors.navy
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: hasText && !isLoading
                          ? [
                              BoxShadow(
                                color: AppColors.navy.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textMuted,
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: hasText
                                ? AppColors.textOnDark
                                : AppColors.textMuted,
                            size: 22,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    int percentage = (progress * 100).round();
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing background circle
                Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.navy
                          .withOpacity(0.05 * (1 - _pulseController.value)),
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    color: AppColors.navy,
                    backgroundColor: AppColors.surfaceVariant,
                    strokeWidth: 6,
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
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                loadingMessage,
                key: ValueKey(loadingMessage),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(currentTip),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentTip,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "This usually takes 1-2 minutes",
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        );
      },
    );
  }
}
