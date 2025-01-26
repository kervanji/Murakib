import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:murakib_vip/teacher/send_attendance_page.dart';

class ChooseClassPage extends StatefulWidget {
  final String teacherUsername;

  const ChooseClassPage({super.key, required this.teacherUsername});

  @override
  State<ChooseClassPage> createState() => _ChooseClassPageState();
}

class _ChooseClassPageState extends State<ChooseClassPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _grades = [];
  String? _teacherSchool;

  @override
  void initState() {
    super.initState();
    _loadTeacherAndGrades();
  }

  Future<void> _loadTeacherAndGrades() async {
    setState(() => _isLoading = true);
    try {
      // Get teacher's school
      final teacherDoc = await _firestore
          .collection('teachers')
          .where('username', isEqualTo: widget.teacherUsername)
          .get();

      if (teacherDoc.docs.isEmpty) {
        throw Exception('Teacher not found');
      }

      _teacherSchool = teacherDoc.docs.first['school'];

      // Get grades for the school
      final gradesSnapshot = await _firestore
          .collection('grades')
          .where('school', isEqualTo: _teacherSchool)
          .get();

      setState(() {
        _grades = gradesSnapshot.docs
            .map((doc) => {
                  'name': doc['name'] as String,
                  'classes': (doc['classes'] as List<dynamic>).cast<String>(),
                })
            .toList();

        // Sort grades by name, handling null safely
        _grades.sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String));
      });
    } catch (e) {
      _showError('Error loading grades: $e');
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
        backgroundColor: Colors.grey.shade800,
        title: const Text(
          'Choose class',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadTeacherAndGrades,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _grades.isEmpty
                  ? const Center(
                      child: Text(
                        'No grades available',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _grades.length,
                      itemBuilder: (context, index) {
                        final grade = _grades[index];
                        final classes = List<String>.from(grade['classes'])
                          ..sort();

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ExpansionTile(
                            backgroundColor: Colors.grey.shade800,
                            collapsedBackgroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              grade['name'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              '${classes.length} ${classes.length == 1 ? 'class' : 'classes'} available',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade300,
                              ),
                            ),
                            children: classes.map((className) {
                              return ListTile(
                                title: Text(
                                  className,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SendAttendancePage(
                                        teacherUsername: widget.teacherUsername,
                                        grade: grade['name'] as String,
                                        className: className,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
