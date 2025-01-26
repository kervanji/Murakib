import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:murakib_vip/teacher/ask_for_leave_page.dart';
import 'package:murakib_vip/teacher/class_selection_page.dart';
import 'package:murakib_vip/teacher/send_message_to_principal_page.dart';

class TeacherHomePage extends StatefulWidget {
  final String teacherUsername;

  const TeacherHomePage({super.key, required this.teacherUsername});

  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  Map<String, dynamic>? _teacherData;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    try {
      final teacherDoc = await _firestore
          .collection('teachers')
          .where('username', isEqualTo: widget.teacherUsername)
          .get();

      if (teacherDoc.docs.isEmpty) {
        _showError('Teacher information not found');
        return;
      }

      setState(() {
        _teacherData = teacherDoc.docs.first.data();
      });
    } catch (e) {
      _showError('Error loading teacher data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
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
          'Teacher Dashboard',
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
          : _teacherData == null
              ? const Center(child: Text('No teacher data found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Teacher Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${_teacherData!['name']}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Subject: ${_teacherData!['subject']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'School: ${_teacherData!['school']}',
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
                            'Take Attendance',
                            Icons.how_to_reg,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClassSelectionPage(
                                  teacherUsername: widget.teacherUsername,
                                  purpose: 'attendance',
                                ),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            'Manage Exams',
                            Icons.assignment,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClassSelectionPage(
                                  teacherUsername: widget.teacherUsername,
                                  purpose: 'exam',
                                ),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            'Request Leave',
                            Icons.event_busy,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AskForLeavePage(
                                  teacherUsername: widget.teacherUsername,
                                ),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            'Contact Principal',
                            Icons.message,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SendMessageToPrincipalPage(
                                  teacherUsername: widget.teacherUsername,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
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
