import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yourapp/utils/ai_operations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

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

    // Errors are collected silently - user can view all in console panel
  }

  List<String> _getAllErrors() {
    return consoleLogs
        .where((log) => log['type'] == 'consoleError')
        .map((log) => log['message'] as String)
        .toList();
  }

  void _showAllErrorsDialog() {
    final errors = _getAllErrors();
    if (errors.isEmpty) return;

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
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${errors.length} Console Error${errors.length > 1 ? 's' : ''}',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: errors
                          .asMap()
                          .entries
                          .map((entry) => Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: EdgeInsets.only(
                                    bottom: entry.key < errors.length - 1
                                        ? 8
                                        : 0),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  entry.value,
                                  style: AppTextStyles.monoSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                    ),
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
                          'Fixing all errors with AI...',
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
                                ? 'All errors fixed and reloaded!'
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
                                final allErrors = errors.join('\n---\n');
                                _fixWithAI(allErrors, setDialogState);
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
                                'Fix All with AI',
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

    if (setDialogState != null) {
      setDialogState(() {
        _isFixing = false;
      });
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
              if (_getAllErrors().isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      '${_getAllErrors().length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
                      _injectFileHandlers();
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
                      _injectFileHandlers();
                      _registerJavaScriptHandlers();
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

        window.addEventListener('unhandledrejection', function(event) {
          var reason = event.reason;
          var msg = reason instanceof Error ? reason.message : String(reason);
          sendToFlutter('consoleError', 'Unhandled Promise Rejection: ' + msg);
        });
      })();
    ''';

    await webViewController.evaluateJavascript(source: script);
  }

  void _injectFileHandlers() async {
    final pickFileScript = '''
      (function() {
        window.FileHandler = {
          pickFile: async function(options) {
            return new Promise(function(resolve, reject) {
              window.flutter_inappwebview.callHandler('pickFile', JSON.stringify(options || {}))
                .then(function(result) {
                  resolve(result);
                })
                .catch(function(err) {
                  reject(err);
                });
            });
          },
          pickFiles: async function(options) {
            return new Promise(function(resolve, reject) {
              window.flutter_inappwebview.callHandler('pickFiles', JSON.stringify(options || {}))
                .then(function(result) {
                  resolve(result);
                })
                .catch(function(err) {
                  reject(err);
                });
            });
          },
          saveFile: async function(data, filename) {
            return new Promise(function(resolve, reject) {
              window.flutter_inappwebview.callHandler('saveFile', JSON.stringify({data: data, filename: filename}))
                .then(function(result) {
                  resolve(result);
                })
                .catch(function(err) {
                  reject(err);
                });
            });
          },
          getAppDocumentsPath: async function() {
            return new Promise(function(resolve, reject) {
              window.flutter_inappwebview.callHandler('getAppDocumentsPath')
                .then(function(result) {
                  resolve(result);
                })
                .catch(function(err) {
                  reject(err);
                });
            });
          },
          getAllMedia: async function(options) {
            return new Promise(function(resolve, reject) {
              window.flutter_inappwebview.callHandler('getAllMedia', JSON.stringify(options || {}))
                .then(function(result) {
                  resolve(result);
                })
                .catch(function(err) {
                  reject(err);
                });
            });
          },
          requestPermission: async function() {
            return new Promise(function(resolve, reject) {
              window.flutter_inappwebview.callHandler('requestMediaPermission')
                .then(function(result) {
                  resolve(result);
                })
                .catch(function(err) {
                  reject(err);
                });
            });
          }
        };
      })();
    ''';

    await webViewController.evaluateJavascript(source: pickFileScript);
  }

  void _registerJavaScriptHandlers() {
    webViewController.addJavaScriptHandler(
      handlerName: 'pickFile',
      callback: (args) async {
        try {
          String type = 'any';
          if (args.isNotEmpty && args[0] is Map) {
            final options = args[0] as Map;
            type = options['type'] as String? ?? 'any';
          }

          FileType fileType;
          switch (type) {
            case 'audio':
              fileType = FileType.audio;
              break;
            case 'video':
              fileType = FileType.video;
              break;
            case 'image':
              fileType = FileType.image;
              break;
            default:
              fileType = FileType.any;
          }

          final result = await FilePicker.platform.pickFiles(type: fileType);
          if (result != null && result.files.isNotEmpty) {
            final file = result.files.first;
            return {
              'name': file.name,
              'path': file.path,
              'size': file.size,
              'extension': file.extension,
            };
          }
          return null;
        } catch (e) {
          return {'error': e.toString()};
        }
      },
    );

    webViewController.addJavaScriptHandler(
      handlerName: 'pickFiles',
      callback: (args) async {
        try {
          final result =
              await FilePicker.platform.pickFiles(allowMultiple: true);
          if (result != null && result.files.isNotEmpty) {
            return result.files
                .map((file) => {
                      'name': file.name,
                      'path': file.path,
                      'size': file.size,
                      'extension': file.extension,
                    })
                .toList();
          }
          return [];
        } catch (e) {
          return [
            {'error': e.toString()}
          ];
        }
      },
    );

    webViewController.addJavaScriptHandler(
      handlerName: 'saveFile',
      callback: (args) async {
        if (args.isEmpty) return {'error': 'No data provided'};
        try {
          final data = args[0];
          final String? filename = data['filename'] as String?;
          if (filename == null) return {'error': 'Filename required'};

          final result = await FilePicker.platform.saveFile(
            fileName: filename,
          );
          return {'path': result};
        } catch (e) {
          return {'error': e.toString()};
        }
      },
    );

    webViewController.addJavaScriptHandler(
      handlerName: 'getAppDocumentsPath',
      callback: (args) async {
        try {
          final directory = await getApplicationDocumentsDirectory();
          return directory.path;
        } catch (e) {
          return {'error': e.toString()};
        }
      },
    );

    webViewController.addJavaScriptHandler(
      handlerName: 'requestMediaPermission',
      callback: (args) async {
        try {
          final permission = await PhotoManager.requestPermissionExtend();
          return {'granted': permission.isAuth};
        } catch (e) {
          return {'error': e.toString()};
        }
      },
    );

    webViewController.addJavaScriptHandler(
      handlerName: 'getAllMedia',
      callback: (args) async {
        try {
          String type = 'all';
          int page = 0;
          int pageSize = 100;

          if (args.isNotEmpty && args[0] is Map) {
            final options = args[0] as Map;
            type = options['type'] as String? ?? 'all';
            page = options['page'] as int? ?? 0;
            pageSize = options['pageSize'] as int? ?? 100;
          }

          FilterOptionGroup filterOptionGroup;
          switch (type) {
            case 'image':
              filterOptionGroup = FilterOptionGroup(
                imageOption: const FilterOption(
                  sizeConstraint: SizeConstraint(ignoreSize: true),
                ),
              );
              break;
            case 'video':
              filterOptionGroup = FilterOptionGroup(
                videoOption: const FilterOption(
                  sizeConstraint: SizeConstraint(ignoreSize: true),
                ),
              );
              break;
            case 'audio':
              filterOptionGroup = FilterOptionGroup(
                audioOption: const FilterOption(
                  sizeConstraint: SizeConstraint(ignoreSize: true),
                ),
              );
              break;
            default:
              filterOptionGroup = FilterOptionGroup(
                imageOption: const FilterOption(
                  sizeConstraint: SizeConstraint(ignoreSize: true),
                ),
                videoOption: const FilterOption(
                  sizeConstraint: SizeConstraint(ignoreSize: true),
                ),
              );
          }

          final albums = await PhotoManager.getAssetPathList(
            type: type == 'image'
                ? RequestType.image
                : type == 'video'
                    ? RequestType.video
                    : type == 'audio'
                        ? RequestType.audio
                        : RequestType.common,
            filterOption: filterOptionGroup,
          );

          if (albums.isEmpty) {
            return [];
          }

          final recentAlbum = albums.first;
          final assets = await recentAlbum.getAssetListPaged(
            page: page,
            size: pageSize,
          );

          final List<Map<String, dynamic>> result = [];
          for (final asset in assets) {
            final file = await asset.file;
            result.add({
              'id': asset.id,
              'title': asset.title,
              'type': asset.type == AssetType.image
                  ? 'image'
                  : asset.type == AssetType.video
                      ? 'video'
                      : 'audio',
              'width': asset.width,
              'height': asset.height,
              'duration': asset.duration,
              'createDateTime': asset.createDateTime.millisecondsSinceEpoch,
              'modifiedDateTime': asset.modifiedDateTime.millisecondsSinceEpoch,
              'path': file?.path,
              'size': file?.lengthSync(),
            });
          }

          return result;
        } catch (e) {
          return [
            {'error': e.toString()}
          ];
        }
      },
    );
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
                if (_getAllErrors().isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _showAllErrorsDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 12, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            '${_getAllErrors().length} error${_getAllErrors().length > 1 ? 's' : ''}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_getAllErrors().isNotEmpty) const SizedBox(width: 6),
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
