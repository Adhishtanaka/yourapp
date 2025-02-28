import 'package:flutter/material.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/utils/ai_operations.dart';
import 'package:yourapp/ui/components/savedWidget.dart';
import 'package:yourapp/ui/components/alertDialogWidget.dart';

class HomeComponent extends StatefulWidget {
  const HomeComponent({super.key});

  @override
  State<HomeComponent> createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent> {
  TextEditingController controller = TextEditingController();

  final gemini = AIOperations();
  double progress = 0.0;
  bool isLoading = false;
  String loadingMessage = "Processing your request...";

  final List<String> loadingMessages = [
    "Analyzing prompt...",
    "Generating content...",
    "Almost done...",
  ];

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {});
    });
  }

  void updateLoadingMessage() {
    if (progress < 0.25) {
      loadingMessage = loadingMessages[0];
    } else if (progress < 0.5) {
      loadingMessage = loadingMessages[1];
    } else {
      loadingMessage = loadingMessages[2];
    }
  }

  Future<void> handleSubmit() async {
    if (controller.text.isEmpty) return;

    setState(() {
      isLoading = true;
      progress = 0.1;
      updateLoadingMessage();
    });

    final finalPrompt = await gemini.getPrompt(controller.text);
    setState(() {
      progress = 0.5;
      updateLoadingMessage();
    });

    if (finalPrompt == null) {
      showErrorDialog(context, "You used a wrong prompt.");
      setState(() {
        isLoading = false;
        progress = 0.0;
      });
      return;
    }

    setState(() {
      progress = 0.75;
      updateLoadingMessage();
    });

    final htmlCode = await gemini.getCode(finalPrompt);
    setState(() {
      progress = 1.0;
      updateLoadingMessage();
    });

    String prompt = controller.text;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BrowserUI(
            html: htmlCode!,
            bottomWidget: SavedWidget(prompt: prompt, html: htmlCode),
          )),
    );
    controller.clear();
    setState(() {
      isLoading = false;
      progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
                child: isLoading
                    ? LoadingUI()
                    : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.android, size: 35),
                        Text("What can I help with?"),
                      ],
                    )
                )
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Type Your Prompt..',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send_rounded,
                          color: controller.text.isEmpty ? Colors.grey[400] : Colors.grey[600],
                          size: 18),
                      onPressed: controller.text.isEmpty || isLoading ? null : handleSubmit,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget LoadingUI() {
    int percentage = (progress * 100).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                value: progress,
                color: Colors.black38,
                backgroundColor: Colors.grey[300],
                strokeWidth: 5,
              ),
            ),
            Text(
              "$percentage%",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          loadingMessage,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),

      ],
    );
  }
}