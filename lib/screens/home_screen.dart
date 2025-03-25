import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'education_screen.dart';
import 'notification_screen.dart';
import 'reports_screen.dart';
import 'AttendanceHistoryScreen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'programs_screen.dart';


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

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
    initFCM();
  }

  Future<void> initFCM() async {
    // Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and send token
    // final fcmToken = await _messaging.getToken();
    // print("🔑 FCM Token: $fcmToken");
    //
    // if (fcmToken != null) {
    //   final response = await http.post(
    //     Uri.parse('https://team7.pythonanywhere.com/save-token'),
    //     body: {
    //       'student_id': widget.userId,
    //       'token': fcmToken,
    //     },
    //   );
    //
    //   if (response.statusCode == 200) {
    //     print("✅ Token successfully sent to backend!");
    //   } else {
    //     print("❌ Failed to send token: ${response.statusCode} - ${response
    //         .body}");
    //   }
    // }

    // Init local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message: ${message.notification?.title}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Ishanya Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
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
        final data = jsonDecode(response.body);
        final attendance = await fetchAttendance(widget.userId);

        if (attendance != null) {
          int present = int.tryParse(attendance['present_days'].toString()) ??
              0;
          int total = int.tryParse(attendance['total_days'].toString()) ?? 0;

          if (total > 0) {
            double percentage = (present / total) * 100;
            data['Attendance'] = '${percentage.toStringAsFixed(1)}%';
          } else {
            data['Attendance'] = 'No attendance data';
          }
        }


        setState(() {
          studentData = data;
          isLoading = false;
        }


          // setState(() {
          //   studentData = jsonDecode(response.body);
          //   isLoading = false;
          //   }
        );
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

  Future<Map<String, dynamic>?> fetchAttendance(String studentId) async {
    final url = Uri.parse(
        'http://team7.pythonanywhere.com/attendance/$studentId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'total_days': data['total_days'],
          'present_days': data['present_days'],
        };
      } else {
        print("Failed to fetch attendance: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching attendance: $e");
      return null;
    }
  }


  Future<void> _logout(BuildContext context) async {
    // Get the current theme for consistent styling
    final theme = Theme.of(context);

    // Define red colors for logout theming
    final Color errorRed = Colors.red.shade700;

    // Show a stylish confirmation dialog with red accents
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final shouldLogout = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Logout?',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: textTheme.bodyMedium,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Logout'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    // Proceed with logout if confirmed
    if (shouldLogout == true) {
      // Show loading indicator with red color
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: errorRed,
          ),
        ),
      );

      try {
        // Clear user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Navigate to login screen and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      } catch (e) {
        // Close loading dialog if error occurs
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget buildStudentDetails() {
    if (studentData == null) {
      return Center(
        child: Text(
          "No data found",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    Map<String, String> fieldLabels = {
      'S_ID': 'Student ID',
      'Gender': 'Gender',
      'DOB': 'Date of Birth',
      'Primary_Diagnosis': 'Primary Diagnosis',
      'Comorbidity': 'Comorbidities',
      'UDID': 'UDID Number',
      'Enrollment_Year': 'Enrollment Year',
      'Status': 'Enrollment Status',
      'Sessions': 'Session Count',
      'Timings': 'Session Timings',
      'Days_of_Week': 'Session Days',
      'Session_Type': 'Session Type',
      'Father': 'Father\'s Name',
      'Mother': 'Mother\'s Name',
      'Blood_Grp': 'Blood Group',
      'Allergies': 'Allergies',
    };

    final educatorFields = {
      'Primary_E_ID': studentData!['Primary_E_ID'],
      'Secondary_E_ID': studentData!['Secondary_E_ID'],
    };

    // Group fields by category for better organization
    final Map<String, List<String>> fieldCategories = {
      'Personal Information': [
        'S_ID',
        'Gender',
        'DOB',
        'Blood_Grp',
        'Allergies'
      ],
      'Medical Details': ['Primary_Diagnosis', 'Comorbidity', 'UDID'],
      'Enrollment Information': ['Enrollment_Year', 'Status'],
      'Session Details': [
        'Sessions',
        'Timings',
        'Days_of_Week',
        'Session_Type'
      ],
      'Family Information': ['Father', 'Mother'],
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        children: [
          SizedBox(height: 16),

          // Profile summary card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      "${studentData!['Fname']?[0] ??
                          ''}${studentData!['Lname']?[0] ?? ''}",
                      style: TextStyle(fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${studentData!['Fname'] ??
                              ''} ${studentData!['Lname'] ?? ''}",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight
                              .bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "ID: ${studentData!['S_ID'] ?? 'N/A'}",
                          style: TextStyle(fontSize: 14, color: Colors
                              .grey[600]),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Status: ${studentData!['Status'] ?? 'N/A'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: studentData!['Status'] == 'Active' ? Colors
                                .green[700] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Categorized information sections
          ...fieldCategories.entries.map((category) {
            final categoryFields = category.value
                .where((key) =>
            studentData![key] != null && studentData![key]
                .toString()
                .trim()
                .isNotEmpty)
                .toList();

            if (categoryFields.isEmpty) return SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Text(
                    category.key,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: categoryFields.map((key) {
                        final label = fieldLabels[key];
                        final value = studentData![key];

                        String displayValue = value.toString();

                        if (key == 'DOB') {
                          try {
                            final parsedDate = DateFormat(
                                'EEE, dd MMM yyyy HH:mm:ss', 'en_US')
                                .parse(value.toString().replaceAll(' GMT', ''));
                            displayValue =
                                DateFormat('yyyy-MM-dd').format(parsedDate);
                          } catch (e) {
                            print("Failed to parse DOB: $e");
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 130,
                                child: Text(
                                  label ?? key,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayValue,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            );
          }),

          // Educators section
          if (educatorFields.values.any((v) =>
          v != null && v
              .toString()
              .trim()
              .isNotEmpty)) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'Educators',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            ...educatorFields.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;

              if (value == null || value
                  .toString()
                  .trim()
                  .isEmpty) return SizedBox.shrink();

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EducationScreen(educatorId: value.toString()),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Icon(Icons.person, color: Colors.indigo),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                key == 'Primary_E_ID'
                                    ? 'Primary Educator'
                                    : 'Secondary Educator',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                value.toString(),
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 24),
          ],

          // Programs section
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Programs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final id = widget.userId;
                print('Navigating to ProgramsScreen with studentId: $id');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProgramsScreen(studentId: id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Icon(Icons.school, color: Colors.purple.shade700),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'View Student Programs',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24),

          // Attendance section
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          if (studentData!['Attendance'] != null && studentData!['Attendance']
              .toString()
              .trim()
              .isNotEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final id = widget.userId;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceHistoryScreen(studentId: id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                            Icons.calendar_today, color: Colors.green.shade700),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Record',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              studentData!['Attendance'].toString(),
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16,
                          color: Colors.grey),
                    ],
                  ),
                ),
              ),
            )
          else
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(Icons.calendar_today, color: Colors.grey),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'No attendance data available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 24),
          // Programs section
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          // Reports section
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final id = widget.userId;
                print('Navigating to ReportsScreen with studentId: $id');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportsScreen(studentId: id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Icon(Icons.insert_drive_file, color: Colors.orange.shade700),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'View Reports',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
// Notifications section
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final id = widget.userId;
                print('Navigating to NotificationsScreen with studentId: $id');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(studentId: widget.userId),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.notifications, color: Colors.blue.shade700),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'View Notifications',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        title: Text(
          'Student Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),

      body: Container(
        color: Colors.grey.shade50,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              SizedBox(height: 16),
              Text(
                error!,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        )
            : buildStudentDetails(),
      ),
    );
  }
}