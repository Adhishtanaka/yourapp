import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class BrowserUI extends StatefulWidget {
  final String html;
  final Widget bottomWidget;
  const BrowserUI({super.key, required this.html, required this.bottomWidget});

  @override
  _BrowserUIState createState() => _BrowserUIState();
}

class _BrowserUIState extends State<BrowserUI> {
  late InAppWebViewController webViewController;
  late PullToRefreshController pullToRefreshController;
  bool isLoading = true;
  bool hasError = false;

  String cleanHtml(String html) {
    return html.replaceAll('```html', '').replaceAll('```', '').trim();
  }

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        webViewController.reload();
      },
    );
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
        ],
      ),
      body: Column(
        children: [
          if (isLoading)
            LinearProgressIndicator(
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              minHeight: 1.5,
            ),
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
                      data: cleanHtml(widget.html),
                      baseUrl: WebUri('https://localhost'),
                    ),
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
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
}
