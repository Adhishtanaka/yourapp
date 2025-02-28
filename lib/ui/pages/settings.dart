import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourapp/ui/components/alertDialogWidget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<void> clearAllRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    if (dir.existsSync()) {
      dir.listSync().forEach((file) {
        if (file is File) {
          file.deleteSync();
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("All data cleared successfully!")),
    );
  }

  Future<void> clearAllData() async {
    await clearAllRecords();
    await storage.delete(key: "api_key");
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text(
                    'API Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          showApiKeyDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Change API Key', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Data Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline, color: Colors.red, size: 28),
                            title: Text(
                              'Clear All Records',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Remove all saved HTML files and records'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              showConfirmationDialog(
                                context: context,
                                title: "Confirm",
                                content: "Are you sure you want to clear all records?",
                                onConfirm: clearAllRecords,
                              );
                            },
                          ),
                          Divider(height: 32),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_forever, color: Colors.red, size: 28),
                            title: Text(
                              'Clear All Data',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Reset all application data including API key and settings'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              showConfirmationDialog(
                                context: context,
                                title: "Confirm",
                                content: "Are you sure you want to clear all data? This action cannot be undone.",
                                onConfirm: clearAllData,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Center(child: Text("Made By Adhishtanaka")),
          ),
        ],
      ),
    );
  }
}