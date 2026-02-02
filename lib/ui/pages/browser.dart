import 'package:flutter/material.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

  String cleanHtml(String html) {
    return html.replaceAll('```html', '').replaceAll('```', '').trim();
  }

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      onRefresh: () async {
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
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Preview',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              webViewController.reload();
            },
          ),
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
                      userAgent:
                          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
                    ),
                    initialData: InAppWebViewInitialData(
                      data: cleanHtml(widget.html),
                      baseUrl: WebUri('https://localhost'),
                    ),
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
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
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: AppColors.navy,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Loading preview...",
                            style: AppTextStyles.bodySmall,
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
