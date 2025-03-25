import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

          // Fetch and send FCM token
          final FirebaseMessaging _messaging = FirebaseMessaging.instance;
          final fcmToken = await _messaging.getToken();
          print("🔑 FCM Token: $fcmToken");

          if (fcmToken != null) {
            final tokenResponse = await http.post(
              Uri.parse('https://team7.pythonanywhere.com/save-token'),
              body: {
                'student_id': id,
                'token': fcmToken,
              },
            );

            if (tokenResponse.statusCode == 200) {
              print("✅ Token successfully sent to backend!");
            } else {
              print("❌ Failed to send token: ${tokenResponse.statusCode} - ${tokenResponse.body}");
            }
          }

          // Navigate to HomeScreen after successfully sending the token
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[300]!, Colors.purple[300]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 40,
                      color: Colors.white,
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Student Login',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                _buildTextField(
                  controller: _idController,
                  label: 'Student ID',
                  icon: Icons.person,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _pwdController,
                  label: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorText!,
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isButtonEnabled ? loginUser : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Text('Login'),
                ),
                // The rest of the screen will remain empty to avoid content shifting
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.blue[700],
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
