import 'package:dpos/page/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dpos/page/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const Homepage() : SimpleLoginPage(),
    );
  }
}
