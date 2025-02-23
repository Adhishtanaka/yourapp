import 'package:flutter/material.dart';
import 'package:yourapp/utils/ai_operations.dart';
import 'package:yourapp/ui/components/browser.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  TextEditingController controller = TextEditingController();
  final gemini = AIOperations(apiKey: '');

  void _showErrorDialog(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle_outlined, size: 19, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text("yourapp", style: TextStyle(color: Colors.grey[600], fontSize: 17)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 6),
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
                        icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[600], size: 18),
                        onPressed: () async {
                          if (controller.text.isNotEmpty) {
                            final finalPrompt = await gemini.getPrompt(controller.text);
                            if (finalPrompt == null) {
                              _showErrorDialog("You used a wrong prompt.");
                              return;
                            }
                            final htmlCode = await gemini.getCode(finalPrompt);
                            if (htmlCode == null) {
                              _showErrorDialog("Failed to generate code.");
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BrowserUI(html: htmlCode)),
                            );
                          }
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10)
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.grey[800],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'New',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}
