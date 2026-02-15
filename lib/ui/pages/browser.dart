import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yourapp/utils/ai_operations.dart';

class BrowserUI extends StatefulWidget {
  final String html;
  final Widget bottomWidget;
  const BrowserUI({super.key, required this.html, required this.bottomWidget});

  @override
  State<BrowserUI> createState() => BrowserUIState();
}

class BrowserUIState extends State<BrowserUI> {
  late InAppWebViewController webViewController;
  late PullToRefreshController pullToRefreshController;
  bool isLoading = true;
  bool hasError = false;
  List<Map<String, dynamic>> consoleLogs = [];
  bool _showConsolePanel = false;
  bool _isFixing = false;
  String? _currentHtml;
  String? _fixingError;
  bool _fixingComplete = false;

  String cleanHtml(String html) {
    return html.replaceAll('```html', '').replaceAll('```', '').trim();
  }

  @override
  void initState() {
    super.initState();
    _currentHtml = cleanHtml(widget.html);
    pullToRefreshController = PullToRefreshController(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        webViewController.reload();
      },
    );
  }

  void _handleConsoleMessage(
      InAppWebViewController controller, ConsoleMessage consoleMessage) {
    if (!mounted) return;

    final level = consoleMessage.messageLevel;
    final message = consoleMessage.message;
    String type = 'log';

    if (level == ConsoleMessageLevel.ERROR) {
      type = 'consoleError';
    } else if (level == ConsoleMessageLevel.WARNING) {
      type = 'consoleWarn';
    }

    setState(() {
      consoleLogs.add({
        'type': type,
        'message': message,
        'timestamp': DateTime.now(),
      });
    });

    if (type == 'consoleError') {
      _showErrorDialog(type, message);
    }
  }

  void _showErrorDialog(String type, String message) {
    final isError = type == 'consoleError';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isError
                            ? AppColors.errorLight
                            : AppColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isError
                            ? Icons.error_outline
                            : Icons.warning_amber_rounded,
                        color: isError ? AppColors.error : AppColors.success,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isError ? 'Console Error' : 'Console Warning',
                        style: AppTextStyles.h3.copyWith(
                          color: isError ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    message,
                    style: AppTextStyles.monoSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isFixing) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Fixing with AI...',
                          style: AppTextStyles.monoSmall.copyWith(
                            color: AppColors.accentBlue,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_fixingComplete && _fixingError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _fixingError!.isEmpty
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _fixingError!.isEmpty
                              ? Icons.check_circle
                              : Icons.error_outline,
                          size: 14,
                          color: _fixingError!.isEmpty
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fixingError!.isEmpty
                                ? 'Code fixed and reloaded!'
                                : _fixingError!,
                            style: AppTextStyles.monoSmall.copyWith(
                              color: _fixingError!.isEmpty
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isFixing
                            ? null
                            : () {
                                Navigator.pop(context);
                                _resetFixState();
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          _fixingComplete ? 'Close' : 'Dismiss',
                          style: AppTextStyles.button,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isFixing || _fixingComplete
                            ? null
                            : () {
                                _fixWithAI(message, setDialogState);
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
                        child: _isFixing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Fix with AI',
                                style: AppTextStyles.button
                                    .copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetFixState() {
    setState(() {
      _fixingError = null;
      _fixingComplete = false;
    });
  }

  Future<void> _fixWithAI(String error,
      [void Function(void Function())? setDialogState]) async {
    if (_currentHtml == null) return;

    if (setDialogState != null) {
      setDialogState(() {
        _isFixing = true;
      });
    }
    setState(() {
      _isFixing = true;
    });

    try {
      final ai = AIOperations();
      final fixedCode = await ai.fixError(error, _currentHtml ?? '');

      if (!mounted) return;

      if (fixedCode != null &&
          fixedCode.isNotEmpty &&
          (fixedCode.contains('<!DOCTYPE') || fixedCode.contains('<html'))) {
        final cleanCode = cleanHtml(fixedCode);
        setState(() {
          _currentHtml = cleanCode;
        });

        await webViewController.loadData(
          data: cleanCode,
          baseUrl: WebUri('https://localhost'),
        );

        if (setDialogState != null) {
          setDialogState(() {
            _fixingComplete = true;
            _fixingError = '';
          });
        }
        setState(() {
          _fixingComplete = true;
          _fixingError = '';
        });
      } else {
        if (setDialogState != null) {
          setDialogState(() {
            _fixingComplete = true;
            _fixingError = 'Could not fix code automatically';
          });
        }
        setState(() {
          _fixingComplete = true;
          _fixingError = 'Could not fix code automatically';
        });
      }
    } catch (e) {
      if (mounted) {
        if (setDialogState != null) {
          setDialogState(() {
            _fixingComplete = true;
            _fixingError = e.toString();
          });
        }
        setState(() {
          _fixingComplete = true;
          _fixingError = e.toString();
        });
      }
    }

    setState(() {
      _isFixing = false;
    });
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
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text('Preview', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            onPressed: () {
              HapticFeedback.lightImpact();
              webViewController.reload();
            },
          ),
          const SizedBox(width: 4),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.terminal_rounded, size: 18),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _showConsolePanel = !_showConsolePanel;
                  });
                },
              ),
              if (consoleLogs.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (isLoading)
            LinearProgressIndicator(
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              minHeight: 1.5,
            ),
          if (_showConsolePanel) _buildConsolePanel(),
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: InAppWebView(
                    initialSettings: InAppWebViewSettings(
                      iframeAllowFullscreen: true,
                      allowsInlineMediaPlayback: true,
                      javaScriptEnabled: true,
                      javaScriptCanOpenWindowsAutomatically: true,
                      supportMultipleWindows: true,
                      useShouldOverrideUrlLoading: true,
                      useOnLoadResource: true,
                      mixedContentMode:
                          MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                      allowContentAccess: true,
                      allowFileAccess: true,
                      userAgent:
                          "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
                    ),
                    initialData: InAppWebViewInitialData(
                      data: _currentHtml ?? cleanHtml(widget.html),
                      baseUrl: WebUri('https://localhost'),
                    ),
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                      _injectConsoleScript();
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      _handleConsoleMessage(controller, consoleMessage);
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                      final uri = navigationAction.request.url;
                      if (uri != null) {
                        final urlString = uri.toString();
                        if (!urlString.startsWith('https://localhost') &&
                            !urlString.startsWith('about:') &&
                            !urlString.startsWith('data:')) {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                          return NavigationActionPolicy.CANCEL;
                        }
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onCreateWindow: (controller, createWindowRequest) async {
                      final url = createWindowRequest.request.url;
                      if (url != null && await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                      return false;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        isLoading = true;
                      });
                    },
                    onLoadStop: (controller, url) {
                      setState(() {
                        isLoading = false;
                      });
                      pullToRefreshController.endRefreshing();
                      _injectConsoleScript();
                    },
                  ),
                ),
                if (isLoading)
                  Container(
                    color: AppColors.background,
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: AppColors.accentBlue,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          widget.bottomWidget,
        ],
      ),
    );
  }

  void _injectConsoleScript() async {
    final script = '''
      (function() {
        function sendToFlutter(type, message) {
          window.flutter_inappwebview.callHandler('consoleLog', type, message);
        }
        
        var originalConsoleLog = console.log;
        var originalConsoleError = console.error;
        var originalConsoleWarn = console.warn;
        
        console.log = function() {
          var msg = Array.from(arguments).map(a => String(a)).join(' ');
          sendToFlutter('consoleLog', msg);
          originalConsoleLog.apply(console, arguments);
        };
        
        console.error = function() {
          var msg = Array.from(arguments).map(a => String(a)).join(' ');
          sendToFlutter('consoleError', msg);
          originalConsoleError.apply(console, arguments);
        };
        
        console.warn = function() {
          var msg = Array.from(arguments).map(a => String(a)).join(' ');
          sendToFlutter('consoleWarn', msg);
          originalConsoleWarn.apply(console, arguments);
        };
        
        window.onerror = function(message, source, lineno, colno, error) {
          sendToFlutter('consoleError', message + ' (line ' + lineno + ')');
          return false;
        };
      })();
    ''';

    await webViewController.evaluateJavascript(source: script);
  }

  Widget _buildConsolePanel() {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  size: 14,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Console',
                  style: AppTextStyles.monoSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${consoleLogs.length} logs',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      consoleLogs.clear();
                    });
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showConsolePanel = false;
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: consoleLogs.isEmpty
                ? Center(
                    child: Text(
                      'No console output',
                      style: AppTextStyles.monoSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: consoleLogs.length,
                    itemBuilder: (context, index) {
                      final log = consoleLogs[consoleLogs.length - 1 - index];
                      final type = log['type'] as String;
                      final message = log['message'] as String;

                      Color textColor = AppColors.textSecondary;
                      IconData icon = Icons.output;

                      if (type == 'consoleError') {
                        textColor = AppColors.error;
                        icon = Icons.error_outline;
                      } else if (type == 'consoleWarn') {
                        textColor = AppColors.success;
                        icon = Icons.warning_amber_rounded;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              icon,
                              size: 12,
                              color: textColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                message,
                                style: AppTextStyles.monoSmall.copyWith(
                                  color: textColor,
                                  fontSize: 10,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
