import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserUI extends StatefulWidget {
  final String html;

  const BrowserUI({super.key, required this.html});

  @override
  State<BrowserUI> createState() => _BrowserUIState();
}

class _BrowserUIState extends State<BrowserUI> {
  InAppWebViewController? webViewController;
  late PullToRefreshController pullToRefreshController;
  bool isLoading = true;

  String cleanHtml(String html) {
    return html.replaceAll('```html', '').replaceAll('```', '').trim();
  }

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.black),
      onRefresh: () {
        webViewController?.reload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(
              iframeAllowFullscreen: true,
              allowsInlineMediaPlayback: true
            ) ,
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
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
