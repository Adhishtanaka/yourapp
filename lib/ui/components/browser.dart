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

  @override
  void initState() {
    super.initState();
    webViewController?.loadData(data: widget.html);
  }

  PullToRefreshController pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.black));

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      pullToRefreshController: pullToRefreshController,
      onWebViewCreated: (controller) {
        webViewController = controller;
        webViewController?.loadData(data: widget.html);
      },
    );
  }
}
