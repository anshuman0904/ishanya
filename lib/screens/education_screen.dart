import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationScreen extends StatefulWidget {
  final String educatorId;

  const EducationScreen({required this.educatorId});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  Map<String, dynamic>? educatorData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchEducatorData();
  }

  Future<void> fetchEducatorData() async {
    const String apiUrl = 'https://team7.pythonanywhere.com/get_educator_by_id';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Employee_ID': widget.educatorId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          educatorData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load educator data';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Educator Profile',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      )
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              error!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      )
          : educatorData == null
          ? Center(
        child: Text(
          "No educator data found",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: educatorData!['Photo'] != null
                  ? NetworkImage(educatorData!['Photo'])
                  : null,
              child: educatorData!['Photo'] == null
                  ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                  : null,
            ),
          ),
          SizedBox(height: 16),
          Text(
            educatorData!['Educator_Name'] ?? 'N/A',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            educatorData!['Designation'] ?? 'N/A',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: educatorData!['Email'] ?? 'N/A',
            iconColor: Colors.blue,
          ),
          SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.phone_outlined,
            title: 'Phone',
            subtitle: educatorData!['Phone'] ?? 'N/A',
            iconColor: Colors.green,
          ),
          // Add more sections as needed
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () async {
          if (subtitle.isEmpty) return;

          Uri uri;

          if (title.toLowerCase() == "phone") {
            // Open WhatsApp chat with number
            final whatsappNumber = subtitle.replaceAll(RegExp(r'\s+'), '');
            uri = Uri.parse("https://wa.me/$whatsappNumber");
          } else if (title.toLowerCase() == "email") {
            // Compose email
            uri = Uri(
              scheme: 'mailto',
              path: subtitle,
            );
          } else {
            // Default to a normal web URL
            uri = Uri.parse(subtitle);
          }

          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $uri');
          }
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
