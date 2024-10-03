import 'dart:async';
import 'package:dpos/page/homepage.dart';
import 'package:dpos/page/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), _navigateToNextScreen);
  }

  void _navigateToNextScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => token != null ? Homepage() : SimpleLoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'dPOS',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
