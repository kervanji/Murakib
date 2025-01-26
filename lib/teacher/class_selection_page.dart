import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:murakib_vip/teacher/send_attendance_page.dart';
import 'package:murakib_vip/teacher/exam_page.dart';

class ClassSelectionPage extends StatefulWidget {
  final String teacherUsername;
  final String purpose; // 'attendance' or 'exam'

  const ClassSelectionPage({
    super.key,
    required this.teacherUsername,
    required this.purpose,
  });

  @override
  _ClassSelectionPageState createState() => _ClassSelectionPageState();
}

class _ClassSelectionPageState extends State<ClassSelectionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _classes = [];
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

      await _loadClasses();
    } catch (e) {
      _showError('Error loading teacher data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClasses() async {
    if (_teacherData == null) return;

    try {
      final classesSnapshot = await _firestore
          .collection('classes')
          .where('teacherUsername', isEqualTo: widget.teacherUsername)
          .get();

      setState(() {
        _classes = classesSnapshot.docs
            .map((doc) => {
                  'grade': doc['grade'] as String,
                  'class': doc['class'] as String,
                  'subject': doc['subject'] as String,
                })
            .toList();

        // Sort by grade and class
        _classes.sort((a, b) {
          int gradeCompare =
              (a['grade'] as String).compareTo(b['grade'] as String);
          if (gradeCompare != 0) return gradeCompare;
          return (a['class'] as String).compareTo(b['class'] as String);
        });
      });
    } catch (e) {
      _showError('Error loading classes: $e');
    }
  }

  void _navigateToNextPage(Map<String, dynamic> classData) {
    final Widget nextPage;

    if (widget.purpose == 'attendance') {
      nextPage = SendAttendancePage(
        teacherUsername: widget.teacherUsername,
        grade: classData['grade'] as String,
        className: classData['class'] as String,
      );
    } else if (widget.purpose == 'exam') {
      nextPage = ExamPage(
        teacherUsername: widget.teacherUsername,
        grade: classData['grade'] as String,
        className: classData['class'] as String,
      );
    } else {
      _showError('Invalid purpose specified');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
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
        title: Text(
          'Select Class for ${widget.purpose.toUpperCase()}',
          style: const TextStyle(color: Colors.white),
        ),
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
                                _teacherData!['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Subject: ${_teacherData!['subject']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Classes List
                      if (_classes.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No classes assigned',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _classes.length,
                          itemBuilder: (context, index) {
                            final classData = _classes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  'Grade ${classData['grade']} - ${classData['class']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Subject: ${classData['subject']}',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _navigateToNextPage(classData),
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
}
