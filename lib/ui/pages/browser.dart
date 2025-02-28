import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserUI extends StatefulWidget {
  final String html;
  final Widget bottomWidget;
  const BrowserUI({super.key, required this.html ,required this.bottomWidget});

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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialSettings: InAppWebViewSettings(
                    iframeAllowFullscreen: true,
                    allowsInlineMediaPlayback: true,
                      userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
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
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          widget.bottomWidget
        ],
      ),
    );
  }
}
