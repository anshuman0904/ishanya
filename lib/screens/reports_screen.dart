import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsScreen extends StatefulWidget {
  final String studentId;

  const ReportsScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> reports = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    final url = Uri.parse('https://team7.pythonanywhere.com/reports');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.studentId, 'userType': 0}),
      );

      if (response.statusCode == 200) {
        setState(() {
          reports = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load reports';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Reports',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : reports.isEmpty
          ? Center(child: Text('No reports available'))
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          final quarter = report['Quarter'] ?? 'N/A';
          final url = report['Report_URL'];

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: url != null && url.toString().isNotEmpty
                  ? () async {
                try {
                  await _launchURL(url);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch URL: $e')),
                  );
                }
              }
                  : null,

              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Icon(Icons.insert_drive_file,
                          color: Colors.indigo.shade700),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Quarter: $quarter',
                        style: TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (url != null &&
                        url.toString().isNotEmpty)
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey)
                    else
                      Text(
                        'N/A',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
