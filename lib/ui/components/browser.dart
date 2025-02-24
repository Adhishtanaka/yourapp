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

  String cleanHtml(String html) {
    String cleaned = html.replaceAll('```html', '').replaceAll('```', '').trim();
    return cleaned;
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
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: cleanHtml(widget.html),
        baseUrl: WebUri('https://localhost'),
      ),
      pullToRefreshController: pullToRefreshController,
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onLoadStop: (controller, url) {
        pullToRefreshController.endRefreshing();
      },
    );
  }
}