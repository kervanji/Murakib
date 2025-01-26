import 'package:flutter/material.dart';
import 'package:murakib_vip/services/firebase_service.dart';
import 'package:murakib_vip/students/attendance_page.dart';
import 'package:murakib_vip/students/exams_page.dart';
import 'package:murakib_vip/students/messages_page.dart';

class StudentHomePage extends StatefulWidget {
  final String studentUsername;

  const StudentHomePage({super.key, required this.studentUsername});

  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final FirebaseService _firebase = FirebaseService.instance;
  bool _isLoading = false;
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
    } catch (e) {
      _showError('Error loading student data: $e');
    } finally {
      setState(() => _isLoading = false);
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
          'Student Home',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
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
                                'Welcome, ${_studentData!['name']}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Grade: ${_studentData!['grade']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Class: ${_studentData!['class']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'School: ${_studentData!['school']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildActionCard(
                            context,
                            'Attendance',
                            Icons.calendar_today,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttendancePage(
                                  studentUsername: widget.studentUsername,
                                ),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            'Exams',
                            Icons.assignment,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExamsPage(
                                  studentUsername: widget.studentUsername,
                                ),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            'Messages',
                            Icons.message,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MessagesPage(
                                  studentUsername: widget.studentUsername,
                                ),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            'Documents',
                            Icons.folder,
                            () {
                              // TODO: Implement documents page
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.black87),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
