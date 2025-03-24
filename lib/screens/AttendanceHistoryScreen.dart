import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String? studentId;

  AttendanceHistoryScreen({required this.studentId});

  @override
  _AttendanceHistoryScreenState createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Map<String, dynamic>> attendanceRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendanceHistory();
  }

  Future<void> fetchAttendanceHistory() async {
    try {
      final response = await http.get(
        Uri.parse('https://team7.pythonanywhere.com/attendance/history/${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          attendanceRecords = List<Map<String, dynamic>>.from(data['attendance_records']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load attendance');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'Attendance History',
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
                isLoading = true;
              });
              fetchAttendanceHistory();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Loading attendance data...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : attendanceRecords.isEmpty
          ? _buildEmptyState()
          : _buildAttendanceList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No Attendance Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no attendance records available for this student.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                fetchAttendanceHistory();
              },
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceSummary(),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = attendanceRecords[index];
                final isPresent = record['Status'] == 'Present';

                return Card(
                  elevation: 0,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPresent ? Icons.check_circle_outline : Icons.cancel_outlined,
                        color: isPresent ? Colors.green : Colors.red,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      _formatDate(record['Date']),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        record['Status'],
                        style: TextStyle(
                          color: isPresent ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    int totalDays = attendanceRecords.length;
    int presentDays = attendanceRecords.where((record) => record['Status'] == 'Present').length;
    int absentDays = totalDays - presentDays;
    double attendancePercentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Days',
                  totalDays.toString(),
                  Colors.blue,
                  Icons.calendar_month,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Present',
                  presentDays.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Absent',
                  absentDays.toString(),
                  Colors.red,
                  Icons.cancel,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Rate',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: attendancePercentage / 100,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: attendancePercentage >= 75 ? Colors.green :
                        attendancePercentage >= 50 ? Colors.orange : Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '${attendancePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: attendancePercentage >= 75 ? Colors.green[700] :
                  attendancePercentage >= 50 ? Colors.orange[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
