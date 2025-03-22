import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  String? _errorText;
  bool _isButtonEnabled = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _idController.addListener(_validateFields);
    _pwdController.addListener(_validateFields);
  }

  void _validateFields() {
    setState(() {
      _isButtonEnabled = _idController.text.isNotEmpty && _pwdController.text.isNotEmpty;
    });
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userType = prefs.getInt('userType');

    if (userId != null && userType == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userId: userId)),
      );
    }
  }

  Future<void> loginUser() async {
    final id = _idController.text;
    final pwd = _pwdController.text;

    final url = Uri.parse('https://team7.pythonanywhere.com/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Id': id, 'pwd': pwd}),
      );

      final data = jsonDecode(response.body);

      if (data['Authenticated'] == true) {
        if (data['Type'] == 0) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', id);
          await prefs.setInt('userType', 0);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userId: id)),
          );
        } else {
          setState(() {
            _errorText = 'Only students are allowed to log in.';
          });
        }
      } else {
        setState(() {
          _errorText = 'Invalid credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Server error. Please try again later.';
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: 'ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _pwdController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorText!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isButtonEnabled ? loginUser : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
