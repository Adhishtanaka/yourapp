import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? loadingFileId;
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

  void _openFile(String path, String? id) async {
    if (loadingFileId != null) return; // Prevent multiple taps

    HapticFeedback.lightImpact();

    setState(() {
      loadingFileId = id;
    });

    try {
      // Small delay for visual feedback
      await Future.delayed(const Duration(milliseconds: 100));

      File file = File(path);
      if (await file.exists()) {
        String content = await file.readAsString();

        if (!mounted) return;

        setState(() {
          loadingFileId = null;
        });

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => BrowserUI(
              html: content,
              bottomWidget: MoreDetailsWideget(context, path),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      } else {
        setState(() {
          loadingFileId = null;
        });
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text("File not found"),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() {
        loadingFileId = null;
      });
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text("Error opening file"),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
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
          if (!isLoading && savedHtmlFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${filteredFiles.length} app${filteredFiles.length != 1 ? 's' : ''}",
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
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
                  hintText: "Search projects...",
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
    final hasSearchQuery = _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                hasSearchQuery
                    ? Icons.search_off_rounded
                    : Icons.folder_open_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearchQuery ? "No results found" : "No projects yet",
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearchQuery
                  ? "Try a different search term"
                  : "Projects you build will appear here",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (!hasSearchQuery) ...[
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppColors.navy,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Tap Build to create your first app",
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
    final isLoadingThis = loadingFileId == file["id"];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLoadingThis ? AppColors.navy : AppColors.border,
          width: isLoadingThis ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoadingThis
              ? null
              : () => _openFile(file["path"] ?? "", file["id"]),
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
                  child: isLoadingThis
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.navy,
                          ),
                        )
                      : Icon(
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
                        isLoadingThis ? "Opening..." : "Tap to open",
                        style: AppTextStyles.caption.copyWith(
                          color: isLoadingThis
                              ? AppColors.navy
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isLoadingThis
                        ? AppColors.navy.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isLoadingThis
                        ? AppColors.navy
                        : AppColors.textSecondary,
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
