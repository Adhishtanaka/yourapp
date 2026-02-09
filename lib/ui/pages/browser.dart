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
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Container(
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
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              'App Preview',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isLoading)
              Text(
                'Loading...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              webViewController.reload();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Loading indicator
          if (isLoading)
            LinearProgressIndicator(
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
              minHeight: 2,
            ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
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
                        // Check if it's an external URL (not localhost/local content)
                        if (!urlString.startsWith('https://localhost') &&
                            !urlString.startsWith('about:') &&
                            !urlString.startsWith('data:')) {
                          // Open external URLs in system browser or new webview
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
                      // Handle window.open() calls - open in external browser
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
                    color: AppColors.surface,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.navy.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                color: AppColors.navy,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Loading preview...",
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Rendering your mobile app",
                            style: AppTextStyles.caption,
                          ),
                        ],
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
