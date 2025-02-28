import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final FlutterSecureStorage storage = FlutterSecureStorage();

Future<void> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required VoidCallback onConfirm,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Text("OK"),
          ),
        ],
      );
    },
  );
}

Future<void> showApiKeyDialog(BuildContext context) async {
  TextEditingController apiKeyController = TextEditingController();
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Add API Key"),
        content: TextField(
          controller: apiKeyController,
          decoration: InputDecoration(
            hintText: "Enter Gemini API Key",
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String apiKey = apiKeyController.text.trim();
              if (apiKey.isNotEmpty) {
                await storage.write(key: "api_key", value: apiKey);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("API Key saved successfully!")),
                );
                Phoenix.rebirth(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      );
    },
  );
}

void showErrorDialog(BuildContext context , String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Error"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
