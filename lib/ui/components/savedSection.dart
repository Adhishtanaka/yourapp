import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedHtmlFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          SnackBar(
            content: Text("File not found"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error opening file"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : filteredFiles.isEmpty
                    ? _buildEmptyState()
                    : _buildFilesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: "Search saved apps...",
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.navy,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading saved apps...",
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No saved apps yet",
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Apps you create will appear here",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredFiles.length,
      itemBuilder: (context, index) {
        final file = filteredFiles[index];
        return _buildFileCard(file, index);
      },
    );
  }

  Widget _buildFileCard(Map<String, String> file, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFile(file["path"] ?? ""),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.code_rounded,
                    color: AppColors.navy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file["prompt"] ?? "Untitled",
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap to open",
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
