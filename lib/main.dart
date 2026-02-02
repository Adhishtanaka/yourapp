import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/pages/home.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for a clean look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  runApp(
    Phoenix(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'yourapp',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
