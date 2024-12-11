import 'package:dpos/page/homepage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleLoginPage extends StatefulWidget {
  @override
  _SimpleLoginPageState createState() => _SimpleLoginPageState();
}

class _SimpleLoginPageState extends State<SimpleLoginPage> {
  late TextEditingController nameController;
  String responseMessage = '';
  bool isLoginSuccess = false;
  bool isLoading = false;
  String loadingText = 'Login';
  int dotCount = 0;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
      loadingText = 'Loading';
      dotCount = 0;
    });

    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!isLoading) {
        timer.cancel();
      }
      setState(() {
        dotCount = (dotCount + 1) % 4;
      });
    });

    String name = nameController.text;

    if (name.isEmpty) {
      setState(() {
        responseMessage = "silahkan isi username terlebih dahulu, atau untuk coba dulu gunakan username = trial";
        isLoading = false;
        loadingText = 'Login';
      });
      return;
    }

    String url = 'https://dposlite.my.id/api/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'name': name},
      );

      print(response.statusCode);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        int user_id = 0;
        if (data.containsKey('user')) {
          Map<String, dynamic> user = data['user'];
          user_id = user['id'];
        }
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String token = data['token'];
        await prefs.setString('token', token);
        await prefs.setString('username', nameController.text);
        await prefs.setInt('user_id', user_id);
        setState(() {
          responseMessage = 'Login Berhasil';
          isLoginSuccess = true;
          isLoading = false;
          loadingText = 'Login';
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
      } else if (response.statusCode == 404) {
        setState(() {
          responseMessage = 'Username tidak ditemukan, atau untuk coba dulu gunakan username = trial';
          isLoginSuccess = false;
          isLoading = false;
          loadingText = 'Login';
        });
      } else {
        setState(() {
          responseMessage = 'Username tidak ditemukan, atau untuk coba dulu gunakan username = trial';
          isLoginSuccess = false;
          isLoading = false;
          loadingText = 'Login';
        });
      }
    } catch (error) {
      setState(() {
        responseMessage = 'Koneksi terputus, Mohon periksa jaringan anda!';
        isLoginSuccess = false;
        isLoading = false;
        loadingText = 'Login';
      });
    }
  }

  final Uri _url = Uri.parse(
      'mailto:digitaleramodern@gmail.com?subject=Bantuan&body=Silakan%20tulis%20pesan%20Anda%20di%20sini');

  Future<void> _launchEmail() async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _showHelpBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hubungi kami:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _launchEmail,
                    child: Text(
                      'digitaleramodern@gmail.com',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 150),
              Center(
                child: Image.asset(
                  'assets/file.jpg',
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 5),
              if (responseMessage.isNotEmpty && !isLoginSuccess)
                Center(
                  child: Text(
                    responseMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (isLoginSuccess)
                Center(
                  child: Text(
                    responseMessage,
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Color(0xff20c0fa),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: isLoading
                        ? Text(
                            'Loading${'.' * dotCount}', // Tampilkan Loading dengan titik-titik yang berubah
                            key: ValueKey('loading'),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Login',
                            key: ValueKey('login'),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showHelpBottomSheet,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bantuan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.help_outline,
                        color: Colors.grey.shade600,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
