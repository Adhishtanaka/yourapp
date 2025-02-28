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

  Future<void> saveHtml(String prompt, String htmlContent ,context) async {
    final id = _uuid.v4();
    final fileName = "$id.html";
    final path = await _getStoragePath();
    final file = File('$path/$fileName');

    await file.writeAsString(htmlContent);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> data = {"id": id, "prompt": prompt, "path": file.path};
    List<String> savedList = prefs.getStringList("saved_html") ?? [];
    savedList.add(data.toString());
    await prefs.setStringList("saved_html", savedList);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
}
