import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
  }

  Future<void> fetchStudentInfo() async {
    const String apiUrl = 'https://team7.pythonanywhere.com/get_student_by_id';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'S_ID': widget.userId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          studentData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load student data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  Widget buildStudentDetails() {
    if (studentData == null) return Text("No data found");

    List<String> fieldOrder = [
      'S_ID',
      'Photo',
      'Gender',
      'DOB',
      'Primary_Diagnosis',
      'Comorbidity',
      'UDID',
      'Enrollment_Year',
      'Status',
      'Email',
      'Program_ID',
      'Program2_ID',
      'Sessions',
      'Timings',
      'Days_of_Week',
      'Primary_E_ID',
      'Secondary_E_ID',
      'Session_Type',
      'Father',
      'Mother',
      'Blood_Grp',
      'Allergies',
      'Contact_No',
      'Alt_Contact_No',
      'Parent_Email',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: fieldOrder.map((key) {
          final value = studentData![key];
          if (value == null) return SizedBox.shrink(); // skip nulls

          if (key == 'Photo') {
            return Card(
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Text('Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Image.network(value, height: 150, errorBuilder: (_, __, ___) => Icon(Icons.error)),
                  SizedBox(height: 8),
                ],
              ),
            );
          }

          return Card(
            child: ListTile(
              title: Text(key, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(value.toString()),
            ),
          );
        }).toList(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: studentData != null
            ? Text(
          '${studentData!['Fname'] ?? ''} ${studentData!['Lname'] ?? ''}',
          style: TextStyle(fontWeight: FontWeight.bold),
        )
            : Text('Welcome'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : buildStudentDetails(),
    );
  }
}
