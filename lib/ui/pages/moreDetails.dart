import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yourapp/ui/pages/home.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/ui/components/savedWidget.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:yourapp/ui/components/alertDialogWidget.dart';

class MoreDetailsScreen extends StatefulWidget {
  final String path;

  const MoreDetailsScreen({super.key, required this.path});

  @override
  State<MoreDetailsScreen> createState() => _MoreDetailsScreenState();
}

class _MoreDetailsScreenState extends State<MoreDetailsScreen> {
  String? _htmlContent;
  String? _prompt;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList("saved_html") ?? [];

    for (String item in savedList) {
      Map<String, dynamic> data = _parseData(item);
      if (data["path"] == widget.path) {
        File file = File(data["path"]);
        if (await file.exists()) {
          setState(() {
            _htmlContent = file.readAsStringSync();
            _prompt = data["prompt"];
          });
        }
        break;
      }
    }
  }

  Map<String, dynamic> _parseData(String data) {
    data = data.replaceAll("{", "").replaceAll("}", "");
    Map<String, String> map = {};
    for (String pair in data.split(", ")) {
      List<String> keyValue = pair.split(": ");
      if (keyValue.length == 2) {
        map[keyValue[0]] = keyValue[1];
      }
    }
    return map;
  }

  Future<void> _deleteHtml() async {
    File file = File(widget.path);
    if (await file.exists()) {
      await file.delete();
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList("saved_html") ?? [];
    savedList.removeWhere((item) => item.contains(widget.path.split('/').last));
    await prefs.setStringList("saved_html", savedList);

    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  String cleanHtml(String html) {
    return html.replaceAll('```html', '').replaceAll('```', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("yourapp")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade300,
                child: _htmlContent != null
                    ? HighlightView(
                  cleanHtml(_htmlContent!),
                  language: 'html',
                  theme: atomOneLightTheme,
                  padding: const EdgeInsets.all(8),
                  textStyle: const TextStyle(fontSize: 14),
                )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _prompt ?? "No Prompt",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BrowserUI(
                            html: _htmlContent!,
                            bottomWidget: SavedWidget(
                              prompt: _prompt!,
                              html: _htmlContent!,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text("Edit Prompt",
                        style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showConfirmationDialog(
                        context: context,
                        title: "Delete App",
                        content: "Do you want to delete the app?",
                        onConfirm: () {
                          _deleteHtml();
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF800000),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text("Delete",
                        style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
