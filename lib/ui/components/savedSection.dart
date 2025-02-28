import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/ui/pages/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourapp/ui/components/moreDetailsWidget.dart';


class SavedComponent extends StatefulWidget {
  const SavedComponent({super.key});

  @override
  _SavedComponentState createState() => _SavedComponentState();
}

class _SavedComponentState extends State<SavedComponent> {
  List<Map<String, String>> savedHtmlFiles = [];
  List<Map<String, String>> filteredFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedHtmlFiles();
    });
  }

  Future<void> _loadSavedHtmlFiles() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedList = prefs.getStringList("saved_html");

    if (savedList != null && savedList.isNotEmpty) {
      try {
        savedHtmlFiles = [];
        for (String item in savedList) {
          try {
            Map<String, dynamic> parsedItem = json.decode(item);
            savedHtmlFiles.add(Map<String, String>.from({
              'id': parsedItem['id']?.toString() ?? '',
              'prompt': parsedItem['prompt']?.toString() ?? '',
              'path': parsedItem['path']?.toString() ?? '',
            }));
          } catch (jsonError) {
            if (item.startsWith('{') && item.endsWith('}')) {
              String content = item.substring(1, item.length - 1);
              List<String> parts = content.split(', ');

              Map<String, String> parsedMap = {};
              for (String part in parts) {
                List<String> keyValue = part.split(': ');
                if (keyValue.length == 2) {
                  parsedMap[keyValue[0]] = keyValue[1];
                }
              }

              if (parsedMap.isNotEmpty) {
                savedHtmlFiles.add(parsedMap);
              }
            }
          }
        }
      } catch (e) {
        savedHtmlFiles = [];
      }
    } else {
      savedHtmlFiles = [];
    }

    setState(() {
      filteredFiles = List.from(savedHtmlFiles);
      isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      filteredFiles = savedHtmlFiles
          .where((file) =>
              file["prompt"]?.toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();
    });
  }

  void _openFile(String path) async {
    try {
      File file = File(path);
      if (await file.exists()) {
        String content = await file.readAsString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrowserUI(
              html: content,
              bottomWidget: MoreDetailsWideget(context, path),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File not found: $path")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: TextField(
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        hintStyle:
                            TextStyle(color: Colors.grey[600], fontSize: 15),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.black87),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(),
                      ),
                    );
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open,
                                size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              "No saved files found",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredFiles.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1),
                        itemBuilder: (context, index) {
                          final file = filteredFiles[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Text(
                              file["prompt"] ?? "No title",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.open_in_new,
                                size: 20,
                              ),
                            ),
                            onTap: () => _openFile(file["path"] ?? ""),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
