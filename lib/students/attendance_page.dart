import 'package:flutter/material.dart';
import 'package:murakib_vip/services/firebase_service.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  final String studentUsername;

  const AttendancePage({super.key, required this.studentUsername});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseService _firebase = FirebaseService.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _attendanceRecords = [];
  Map<String, dynamic>? _studentData;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final students = await _firebase.queryCollection(
        collection: 'students',
        field: 'username',
        value: widget.studentUsername,
      );

      if (students.isEmpty) {
        _showError('Student information not found');
        return;
      }

      setState(() {
        _studentData = students.first;
      });

      await _loadAttendance();
    } catch (e) {
      _showError('Error loading student data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendance() async {
    if (_studentData == null) return;

    try {
      final attendanceSnapshot = await _firebase.queryCollection(
        collection: 'attendance',
        field: 'studentUsername',
        value: widget.studentUsername,
      );

      setState(() {
        _attendanceRecords = attendanceSnapshot.map((doc) => {
          'date': doc['date'] as String,
          'status': doc['status'] as String,
          'time': doc['time'] as String,
        }).toList();

        // Sort by date, newest first
        _attendanceRecords.sort((a, b) => b['date'].compareTo(a['date']));
      });
    } catch (e) {
      _showError('Error loading attendance records: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          'Attendance Records',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentData == null
              ? const Center(child: Text('No student data found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Student Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _studentData!['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Grade: ${_studentData!['grade']} | Class: ${_studentData!['class']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Attendance Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attendance Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryItem(
                                    'Present',
                                    _attendanceRecords
                                        .where((r) => r['status'] == 'present')
                                        .length
                                        .toString(),
                                    Colors.green,
                                  ),
                                  _buildSummaryItem(
                                    'Absent',
                                    _attendanceRecords
                                        .where((r) => r['status'] == 'absent')
                                        .length
                                        .toString(),
                                    Colors.red,
                                  ),
                                  _buildSummaryItem(
                                    'Total',
                                    _attendanceRecords.length.toString(),
                                    Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Attendance Records
                      if (_attendanceRecords.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No attendance records found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _attendanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = _attendanceRecords[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  DateFormat('EEEE, MMM dd, yyyy')
                                      .format(DateTime.parse(record['date'])),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('Time: ${record['time']}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: record['status'] == 'present'
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    record['status'].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
