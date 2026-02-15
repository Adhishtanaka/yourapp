import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/browser.dart';
import 'package:yourapp/ui/pages/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourapp/ui/components/more_details_widget.dart';

class SavedComponent extends StatefulWidget {
  const SavedComponent({super.key});

  @override
  State<SavedComponent> createState() => SavedComponentState();
}

class SavedComponentState extends State<SavedComponent> {
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
    if (loadingFileId != null) return;

    HapticFeedback.lightImpact();

    setState(() {
      loadingFileId = id;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      File file = File(path);
      if (await file.exists()) {
        String content = await file.readAsString();

        setState(() {
          loadingFileId = null;
        });

        if (!mounted) return;

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => BrowserUI(
              html: content,
              bottomWidget: moreDetailsWidget(context, path),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("File not found"),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } catch (e) {
      setState(() {
        loadingFileId = null;
      });
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error opening file"),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          margin: const EdgeInsets.all(12),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    "${filteredFiles.length} app${filteredFiles.length != 1 ? 's' : ''}",
                    style: AppTextStyles.monoSmall.copyWith(
                      color: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                style: AppTextStyles.mono,
                decoration: InputDecoration(
                  hintText: "> search",
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  hintStyle: AppTextStyles.mono.copyWith(
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppColors.accentBlue,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearchQuery = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              hasSearchQuery
                  ? Icons.search_off_rounded
                  : Icons.folder_open_rounded,
              size: 24,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearchQuery ? "No results" : "No projects yet",
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoadingThis
              ? null
              : () => _openFile(file["path"] ?? "", file["id"]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.html_rounded,
                  color: AppColors.accentBlue,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file["prompt"] ?? "Untitled",
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLoadingThis)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.accentBlue,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
