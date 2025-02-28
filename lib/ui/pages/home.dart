import 'package:flutter/material.dart';
import 'package:yourapp/ui/components/homeSection.dart';
import 'package:yourapp/ui/components/savedSection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yourapp/ui/components/alertDialogWidget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _checkApi();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isDenied) {
      openAppSettings();
    }
  }

  Future<void> _checkApi() async {
      String? apiKey = await getApiKey();
      if (apiKey == null) {
        showApiKeyDialog(context);
      }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<String?> getApiKey() async {
    final FlutterSecureStorage storage = FlutterSecureStorage();
    return await storage.read(key: "api_key");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeComponent(),
          SavedComponent(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
