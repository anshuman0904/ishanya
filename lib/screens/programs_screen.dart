import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class ProgramsScreen extends StatefulWidget {
  final String studentId;

  const ProgramsScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  _ProgramsScreenState createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  late Future<List<dynamic>> _programsFuture;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _programsFuture = fetchPrograms();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchPrograms() async {
    final url = Uri.parse(
        'https://team7.pythonanywhere.com/get_student_programs?student_id=${widget.studentId}');

    try {
      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData is List) {
          return decodedData;
        } else {
          throw Exception("Unexpected response format: Expected a list.");
        }
      } else {
        throw Exception('Failed to load programs. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Something went wrong. Please try again.\nDetails: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'Enrolled Programs',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _programsFuture = fetchPrograms();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _programsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStateWidget();
          } else {
            return _buildProgramsList(snapshot.data!);
          }
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading your programs...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _programsFuture = fetchPrograms();
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 48,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Programs Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You are not enrolled in any programs yet.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _programsFuture = fetchPrograms();
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade700),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramsList(List<dynamic> programs) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional: Add heading
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20),
          //   child: Text(
          //     'Your Enrolled Programs',
          //     style: TextStyle(
          //       fontSize: 20,
          //       fontWeight: FontWeight.bold,
          //       color: Colors.grey.shade800,
          //     ),
          //   ),
          // ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          //   child: Text(
          //     'Tap on a program to see more details',
          //     style: TextStyle(
          //       fontSize: 14,
          //       color: Colors.grey.shade600,
          //     ),
          //   ),
          // ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: programs.length,
              itemBuilder: (context, index) {
                final program = programs[index];
                final programId = program['Program_ID']?.toString() ?? 'Unknown ID';
                final programName = program['Program_Name'] ?? 'Unnamed Program';

                final color = Colors.primaries[programName.length % Colors.primaries.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // TODO: Navigate to program details
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Program Name
                            Expanded(
                              child: Text(
                                programName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Program ID
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ID: $programId',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
