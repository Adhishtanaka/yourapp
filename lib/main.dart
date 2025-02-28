import 'package:flutter/material.dart';
import 'package:yourapp/ui/pages/home.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';


Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    Phoenix(
      child: MyApp(),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
