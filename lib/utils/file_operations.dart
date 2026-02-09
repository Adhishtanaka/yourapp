import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:yourapp/ui/pages/home.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileOperations {
  final Uuid _uuid = Uuid();

  Future<String> _getStoragePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> saveHtml(String prompt, String htmlContent, context, {String? spec}) async {
    final id = _uuid.v4();
    final fileName = "$id.html";
    final path = await _getStoragePath();
    final file = File('$path/$fileName');

    await file.writeAsString(htmlContent);

    // Save spec file alongside the HTML if provided
    if (spec != null && spec.isNotEmpty) {
      final specFile = File('$path/$id.spec.txt');
      await specFile.writeAsString(spec);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> data = {
      "id": id,
      "prompt": prompt,
      "path": file.path,
      "hasSpec": (spec != null && spec.isNotEmpty) ? "true" : "false",
    };
    List<String> savedList = prefs.getStringList("saved_html") ?? [];
    savedList.add(data.toString());
    await prefs.setStringList("saved_html", savedList);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }

  Future<String?> loadSpec(String htmlPath) async {
    try {
      // Derive spec path from HTML path: replace .html with .spec.txt
      final specPath = htmlPath.replaceAll('.html', '.spec.txt');
      final specFile = File(specPath);
      if (await specFile.exists()) {
        return await specFile.readAsString();
      }
    } catch (_) {}
    return null;
  }
}
