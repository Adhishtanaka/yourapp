import 'package:flutter/material.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/utils/ai_operations.dart';
import 'package:yourapp/utils/file_operations.dart';
import 'package:yourapp/ui/components/alertDialogWidget.dart';

class SavedWidget extends StatefulWidget {
  final String prompt;
  final String html;

  const SavedWidget({super.key, required this.prompt, required this.html});

  @override
  _SavedWidgetState createState() => _SavedWidgetState();
}

class _SavedWidgetState extends State<SavedWidget> {
  late TextEditingController _controller;
  final gemini = AIOperations();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final newHtmlCode = await gemini.editCode(widget.html, _controller.text);
    _controller.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrowserUI(
          html: newHtmlCode!,
          bottomWidget: SavedWidget(prompt: widget.prompt, html: newHtmlCode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Edit your application...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send_sharp, color: Colors.grey[700], size: 18),
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4,vertical: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              showConfirmationDialog(
                context: context,
                title: "Save App",
                content: "Do you want to save the App?",
                onConfirm: () {
                  FileOperations fo = FileOperations();
                  fo.saveHtml(widget.prompt, widget.html,context);
                },
              );
            },
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
