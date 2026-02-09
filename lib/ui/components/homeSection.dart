import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/utils/ai_operations.dart';
import 'package:yourapp/ui/components/savedWidget.dart';

class HomeComponent extends StatefulWidget {
  const HomeComponent({super.key});

  @override
  State<HomeComponent> createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent>
    with TickerProviderStateMixin {
  TextEditingController controller = TextEditingController();

  final gemini = AIOperations();
  bool isLoading = false;

  // Spec-driven state
  // phases: idle | analyzing | reviewSpec | building | done
  String _phase = 'idle';
  String? _specContent;
  String? _errorMessage;
  String? _userPrompt; // original user input
  late AnimationController _pulseController;
  late ScrollController _specScrollController;
  late TextEditingController _specEditController;
  bool _isEditingSpec = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _specScrollController = ScrollController();
    _specEditController = TextEditingController();
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _specScrollController.dispose();
    _specEditController.dispose();
    controller.dispose();
    super.dispose();
  }

  // ── Phase 1: User submits idea → AI generates spec ──
  Future<void> _handleSubmitIdea() async {
    if (controller.text.isEmpty) return;

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    setState(() {
      _phase = 'analyzing';
      _specContent = null;
      _errorMessage = null;
      _isEditingSpec = false;
      _userPrompt = controller.text;
      isLoading = true;
    });

    final spec = await gemini.getPrompt(controller.text);

    if (!mounted) return;

    if (spec == null) {
      setState(() {
        _phase = 'idle';
        isLoading = false;
        _errorMessage =
            "That doesn't look like a mobile app idea. Describe an app you'd like to build.";
      });
      return;
    }

    // Spec generated → pause for user review
    setState(() {
      _phase = 'reviewSpec';
      _specContent = spec;
      _specEditController.text = spec;
      isLoading = false;
    });
  }

  // ── Phase 2: User approves spec → AI builds code ──
  Future<void> _handleApproveSpec() async {
    if (_specContent == null) return;

    HapticFeedback.mediumImpact();

    // If user was editing, grab the edited text
    final specToUse =
        _isEditingSpec ? _specEditController.text : _specContent!;

    setState(() {
      _phase = 'building';
      _specContent = specToUse;
      _isEditingSpec = false;
      isLoading = true;
    });

    final htmlCode = await gemini.getCode(specToUse);

    if (!mounted) return;

    if (htmlCode == null) {
      setState(() {
        _phase = 'reviewSpec'; // go back to spec so they can retry
        isLoading = false;
        _errorMessage = "Failed to build the app. You can edit the spec and try again.";
      });
      return;
    }

    HapticFeedback.heavyImpact();

    final prompt = _userPrompt ?? controller.text;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrowserUI(
          html: htmlCode,
          bottomWidget:
              SavedWidget(prompt: prompt, html: htmlCode, spec: specToUse),
        ),
      ),
    );

    // Reset state
    controller.clear();
    setState(() {
      _phase = 'idle';
      _specContent = null;
      _userPrompt = null;
      _errorMessage = null;
      isLoading = false;
    });
  }

  // ── User rejects spec → back to input ──
  void _handleRejectSpec() {
    HapticFeedback.lightImpact();
    setState(() {
      _phase = 'idle';
      _specContent = null;
      _isEditingSpec = false;
      isLoading = false;
    });
  }

  // ── User wants to regenerate spec ──
  Future<void> _handleRegenerateSpec() async {
    if (_userPrompt == null) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _phase = 'analyzing';
      _specContent = null;
      _isEditingSpec = false;
      isLoading = true;
    });

    final spec = await gemini.getPrompt(_userPrompt!);

    if (!mounted) return;

    if (spec == null) {
      setState(() {
        _phase = 'idle';
        isLoading = false;
        _errorMessage = "Failed to generate spec. Please try again.";
      });
      return;
    }

    setState(() {
      _phase = 'reviewSpec';
      _specContent = spec;
      _specEditController.text = spec;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _buildPhaseUI(),
    );
  }

  Widget _buildPhaseUI() {
    switch (_phase) {
      case 'analyzing':
        return _buildAnalyzingUI();
      case 'reviewSpec':
        return _buildSpecReviewUI();
      case 'building':
        return _buildBuildingUI();
      default:
        // idle
        return Column(
          children: [
            Expanded(
              child: Center(
                child: _errorMessage != null
                    ? _buildErrorUI()
                    : _buildWelcomeUI(),
              ),
            ),
            _buildInputSection(),
          ],
        );
    }
  }

  // ──────────────────────────────────────────
  // PHASE: Analyzing (spinner while spec generates)
  // ──────────────────────────────────────────

  Widget _buildAnalyzingUI() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.06),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.navy,
                        AppColors.navy.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withOpacity(
                            0.3 * (1 - _pulseController.value * 0.5)),
                        blurRadius: 20 + (_pulseController.value * 8),
                        spreadRadius: _pulseController.value * 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Generating Spec',
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing your idea and writing the specification...',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),
              _buildAnimatedDots(),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────
  // PHASE: Review Spec (user reads, edits, approves)
  // ──────────────────────────────────────────

  Widget _buildSpecReviewUI() {
    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _handleRejectSpec,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Specification',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isEditingSpec ? 'Editing — modify the spec below' : 'Review the spec before building',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit/View toggle
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_isEditingSpec) {
                      // Save edits back
                      _specContent = _specEditController.text;
                    }
                    _isEditingSpec = !_isEditingSpec;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isEditingSpec
                        ? AppColors.navy.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: _isEditingSpec
                        ? Border.all(color: AppColors.navy.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isEditingSpec ? Icons.visibility_rounded : Icons.edit_rounded,
                        size: 16,
                        color: _isEditingSpec ? AppColors.navy : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isEditingSpec ? 'Preview' : 'Edit',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isEditingSpec ? AppColors.navy : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error banner (if build failed and came back here)
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.error.withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _errorMessage = null),
                  child: Icon(Icons.close, size: 16, color: AppColors.error),
                ),
              ],
            ),
          ),

        // Spec content
        Expanded(
          child: _isEditingSpec ? _buildSpecEditor() : _buildSpecReadView(),
        ),

        // Action buttons
        _buildSpecActionButtons(),
      ],
    );
  }

  Widget _buildSpecReadView() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _specScrollController,
        child: _buildFormattedSpec(_specContent!),
      ),
    );
  }

  Widget _buildSpecEditor() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navy.withOpacity(0.3), width: 1.5),
      ),
      child: TextField(
        controller: _specEditController,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSpecActionButtons() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary: Approve & Build
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleApproveSpec,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.textOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Approve & Build',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Secondary row: Regenerate & Discard
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleRegenerateSpec,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Regenerate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleRejectSpec,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Discard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // PHASE: Building (spinner while code generates)
  // ──────────────────────────────────────────

  Widget _buildBuildingUI() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.06),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.navy,
                        AppColors.navy.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withOpacity(
                            0.3 * (1 - _pulseController.value * 0.5)),
                        blurRadius: 20 + (_pulseController.value * 8),
                        spreadRadius: _pulseController.value * 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.code_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Building Your App',
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Turning your approved spec into a working app...',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Spec approved',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildAnimatedDots(),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────
  // PHASE: Idle (welcome + input)
  // ──────────────────────────────────────────

  Widget _buildErrorUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text("Something went wrong", style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => setState(() => _errorMessage = null),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text("Try again"),
            style: TextButton.styleFrom(foregroundColor: AppColors.navy),
          ),
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
            // App icon with gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, Color(0xFF1E3A5F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Spec-Driven\nApp Builder",
              textAlign: TextAlign.center,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textPrimary,
                height: 1.15,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "MOBILE APPS ONLY",
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Describe your app → We generate a spec → Then build it",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            _buildHowItWorks(),
            const SizedBox(height: 28),
            _buildSuggestionChips(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      {'icon': Icons.edit_note_rounded, 'label': 'Describe'},
      {'icon': Icons.description_rounded, 'label': 'Spec'},
      {'icon': Icons.phone_android_rounded, 'label': 'Preview'},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.textMuted,
            );
          }
          final step = steps[index ~/ 2];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  step['icon'] as IconData,
                  size: 22,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step['label'] as String,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
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
                    hintText: 'Describe your mobile app idea...',
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
                  onTap: hasText && !isLoading ? _handleSubmitIdea : null,
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

  // ──────────────────────────────────────────
  // Shared widgets
  // ──────────────────────────────────────────

  Widget _buildAnimatedDots() {
    return SizedBox(
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final delay = index * 0.15;
              final value = ((_pulseController.value + delay) % 1.0);
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navy.withOpacity(0.3 + value * 0.7),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildFormattedSpec(String spec) {
    final lines = spec.split('\n');
    List<Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else if (trimmed.startsWith('===') && trimmed.endsWith('===')) {
        final title = trimmed.replaceAll('===', '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF93C5FD),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (trimmed.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.circle, size: 4, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trimmed.substring(2),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFCBD5E1),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (trimmed.contains(':') && !trimmed.startsWith('-')) {
        final colonIndex = trimmed.indexOf(':');
        final key = trimmed.substring(0, colonIndex);
        final value = trimmed.substring(colonIndex + 1).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$key: ',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE2E8F0),
                      height: 1.4,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              trimmed,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFFCBD5E1),
                height: 1.4,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
