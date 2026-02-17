import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/utils/ai_operations.dart';
import 'package:yourapp/ui/components/saved_widget.dart';

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

  // phases: idle | analyzing | reviewSpec | building
  String _phase = 'idle';
  String? _specContent;
  String? _errorMessage;
  String? _userPrompt;
  late AnimationController _pulseController;
  late ScrollController _specScrollController;
  late TextEditingController _specEditController;
  bool _isEditingSpec = false;
  String? _aiFeedback;
  bool _isGettingFeedback = false;

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

    try {
      final spec = await gemini.getPrompt(controller.text);

      if (!mounted) return;

      if (spec == null) {
        setState(() {
          _phase = 'idle';
          isLoading = false;
          _errorMessage = "Not a valid app idea. Try describing a mobile app.";
        });
        return;
      }

      setState(() {
        _phase = 'reviewSpec';
        _specContent = spec;
        _specEditController.text = spec;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final aiError = AIException.fromError(e);
      setState(() {
        _phase = 'idle';
        isLoading = false;
        _errorMessage = aiError.userMessage;
      });
    }
  }

  Future<void> _handleApproveSpec() async {
    if (_specContent == null) return;

    HapticFeedback.mediumImpact();

    final specToUse = _isEditingSpec ? _specEditController.text : _specContent!;

    setState(() {
      _phase = 'building';
      _specContent = specToUse;
      _isEditingSpec = false;
      isLoading = true;
      _aiFeedback = null;
    });

    try {
      final htmlCode = await gemini.getCode(specToUse);

      if (!mounted) return;

      if (htmlCode == null) {
        setState(() {
          _phase = 'reviewSpec';
          isLoading = false;
          _errorMessage = "Build failed. Edit spec and retry.";
        });
        return;
      }

      setState(() {
        _isGettingFeedback = true;
      });

      final feedback = await _getCodeFeedback(specToUse);

      if (!mounted) return;

      setState(() {
        _aiFeedback = feedback;
        _isGettingFeedback = false;
      });

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

      controller.clear();
      setState(() {
        _phase = 'idle';
        _specContent = null;
        _userPrompt = null;
        _errorMessage = null;
        _aiFeedback = null;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final aiError = AIException.fromError(e);
      setState(() {
        _phase = 'reviewSpec';
        isLoading = false;
        _errorMessage = aiError.userMessage;
      });
    }
  }

  Future<String> _getCodeFeedback(String spec) async {
    try {
      final feedbackPrompt = '''
You are generating a mobile app. Briefly explain what this app will do in 1-2 sentences based on the spec:

$spec

Response format: "This app [what it does]"
''';
      final content = [Content.text(feedbackPrompt)];
      final response = await gemini.model.generateContent(content);
      return response.text?.trim() ?? 'Building your app...';
    } catch (e) {
      return 'Building your app...';
    }
  }

  void _handleRejectSpec() {
    HapticFeedback.lightImpact();
    setState(() {
      _phase = 'idle';
      _specContent = null;
      _isEditingSpec = false;
      isLoading = false;
    });
  }

  Future<void> _handleRegenerateSpec() async {
    if (_userPrompt == null) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _phase = 'analyzing';
      _specContent = null;
      _isEditingSpec = false;
      isLoading = true;
    });

    try {
      final spec = await gemini.getPrompt(_userPrompt!);

      if (!mounted) return;

      if (spec == null) {
        setState(() {
          _phase = 'idle';
          isLoading = false;
          _errorMessage = "Failed to generate spec.";
        });
        return;
      }

      setState(() {
        _phase = 'reviewSpec';
        _specContent = spec;
        _specEditController.text = spec;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final aiError = AIException.fromError(e);
      setState(() {
        _phase = 'idle';
        isLoading = false;
        _errorMessage = aiError.userMessage;
      });
    }
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
        return Column(
          children: [
            Expanded(
              child: Center(
                child:
                    _errorMessage != null ? _buildErrorUI() : _buildWelcomeUI(),
              ),
            ),
            _buildInputSection(),
          ],
        );
    }
  }

  // ── Analyzing ──

  Widget _buildAnalyzingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.4 + (_pulseController.value * 0.6),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 36,
                  color: AppColors.accentBlue,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'generating spec...',
            style: AppTextStyles.monoSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Spec Review ──

  Widget _buildSpecReviewUI() {
    return Column(
      children: [
        // Tab-style header
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _handleRejectSpec,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child:
                      Icon(Icons.close, color: AppColors.textMuted, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.description_outlined,
                size: 14,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'spec.md',
                style: AppTextStyles.monoSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_isEditingSpec) {
                      _specContent = _specEditController.text;
                    }
                    _isEditingSpec = !_isEditingSpec;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isEditingSpec
                        ? AppColors.accentBlue.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    _isEditingSpec ? 'preview' : 'edit',
                    style: AppTextStyles.monoSmall.copyWith(
                      color: _isEditingSpec
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error banner
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.errorLight,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _errorMessage = null),
                  child:
                      const Icon(Icons.close, size: 14, color: AppColors.error),
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
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        controller: _specScrollController,
        child: _buildFormattedSpec(_specContent!),
      ),
    );
  }

  Widget _buildSpecEditor() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accentBlue, width: 1),
      ),
      child: TextField(
        controller: _specEditController,
        maxLines: null,
        expands: true,
        style: AppTextStyles.mono.copyWith(fontSize: 12),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildSpecActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleApproveSpec,
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
                    const Icon(Icons.play_arrow_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Build',
                        style:
                            AppTextStyles.button.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleRegenerateSpec,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Icon(Icons.refresh, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleRejectSpec,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Building ──

  Widget _buildBuildingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.4 + (_pulseController.value * 0.6),
                child: const Icon(
                  Icons.code_rounded,
                  size: 36,
                  color: AppColors.accentBlue,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _isGettingFeedback ? 'analyzing...' : 'building...',
            style: AppTextStyles.monoSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 10, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'spec approved',
                style: AppTextStyles.caption.copyWith(color: AppColors.success),
              ),
            ],
          ),
          if (_aiFeedback != null) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _aiFeedback!,
                style: AppTextStyles.monoSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Idle ──

  Widget _buildErrorUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
            child: const Icon(Icons.error_outline,
                size: 24, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Text('Error', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentBlue),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.terminal_rounded,
          size: 32,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 12),
        Text(
          'describe. spec. build.',
          style: AppTextStyles.monoSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    final hasText = controller.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: hasText ? AppColors.accentBlue : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: AppTextStyles.mono,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: '> describe your app',
                    hintStyle: AppTextStyles.mono.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: hasText && !isLoading ? _handleSubmitIdea : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasText && !isLoading
                          ? AppColors.accentBlue
                          : AppColors.elevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textMuted,
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: hasText ? Colors.white : AppColors.textMuted,
                            size: 18,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  // ── Formatted spec renderer ──

  Widget _buildFormattedSpec(String spec) {
    final lines = spec.split('\n');
    List<Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 4));
      } else if (trimmed.startsWith('===') && trimmed.endsWith('===')) {
        final title = trimmed.replaceAll('===', '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.monoSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                      letterSpacing: 0.5,
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
            padding: const EdgeInsets.only(left: 6, top: 1, bottom: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trimmed.substring(2),
                    style: AppTextStyles.monoSmall.copyWith(
                      color: AppColors.textSecondary,
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
            padding: const EdgeInsets.only(left: 6, top: 1, bottom: 1),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$key: ',
                    style: AppTextStyles.monoSmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: AppTextStyles.monoSmall.copyWith(
                      color: AppColors.textMuted,
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
              style: AppTextStyles.monoSmall.copyWith(
                color: AppColors.textSecondary,
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
