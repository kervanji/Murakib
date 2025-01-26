import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExamPage extends StatefulWidget {
  final String teacherUsername;
  final String grade;
  final String className;

  const ExamPage({
    super.key,
    required this.teacherUsername,
    required this.grade,
    required this.className,
  });

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  List<TextEditingController> _markControllers = [];
  String? _teacherSchool;
  String? selectedLesson;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    for (var controller in _markControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    try {
      // Get teacher's school
      final teacherDoc = await _firestore
          .collection('teachers')
          .where('username', isEqualTo: widget.teacherUsername)
          .get();

      if (teacherDoc.docs.isEmpty) {
        _showError('Teacher not found');
        setState(() => _isLoading = false);
        return;
      }

      _teacherSchool = teacherDoc.docs.first['school'] as String;
      await _loadStudents();
    } catch (e) {
      _showError('Error loading teacher data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_teacherSchool == null) return;

    try {
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('school', isEqualTo: _teacherSchool)
          .where('grade', isEqualTo: widget.grade)
          .where('class', isEqualTo: widget.className)
          .orderBy('name')
          .get();

      setState(() {
        _students = studentsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] as String,
                  'username': doc['username'] as String,
                })
            .toList();

        // Create controllers for each student
        _markControllers = List.generate(
          _students.length,
          (index) => TextEditingController(),
        );
      });
    } catch (e) {
      _showError('Error loading students: $e');
    }
  }

  final List<String> lessons = [
    "Math",
    "Science",
    "History",
    "English",
    "Arabic",
    "Islamic Studies",
    "Social Studies",
    "Computer Science",
    "Physical Education"
  ];

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  bool _validateMarks() {
    for (int i = 0; i < _markControllers.length; i++) {
      final mark = _markControllers[i].text.trim();
      if (mark.isEmpty) {
        _showError('Please enter mark for ${_students[i]['name']}');
        return false;
      }
      final markValue = double.tryParse(mark);
      if (markValue == null || markValue < 0 || markValue > 100) {
        _showError(
            'Invalid mark for ${_students[i]['name']}. Mark should be between 0 and 100');
        return false;
      }
    }
    return true;
  }

  Future<void> _submitMarks() async {
    if (selectedLesson == null) {
      _showError('Please select a lesson');
      return;
    }

    if (!_validateMarks()) return;

    setState(() => _isLoading = true);
    try {
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      // Create exam record
      final examRef = _firestore.collection('exams').doc();
      batch.set(examRef, {
        'grade': widget.grade,
        'class': widget.className,
        'lesson': selectedLesson,
        'date': timestamp,
        'teacherUsername': widget.teacherUsername,
        'school': _teacherSchool,
        'createdAt': timestamp,
      });

      // Add marks for each student
      for (int i = 0; i < _students.length; i++) {
        final markRef = examRef.collection('marks').doc(_students[i]['id']);
        batch.set(markRef, {
          'studentId': _students[i]['id'],
          'studentName': _students[i]['name'],
          'username': _students[i]['username'],
          'mark': double.parse(_markControllers[i].text.trim()),
          'timestamp': timestamp,
        });

        // Create notification for each student
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipientUsername': _students[i]['username'],
          'type': 'exam_mark',
          'title': 'New Exam Mark',
          'message':
              'You got ${_markControllers[i].text.trim()}% in $selectedLesson exam',
          'timestamp': timestamp,
          'isRead': false,
          'examId': examRef.id,
          'mark': double.parse(_markControllers[i].text.trim()),
        });
      }

      await batch.commit();
      _showSuccess(
          'Marks submitted successfully for ${_students.length} students');

      // Clear the form
      setState(() {
        selectedLesson = null;
        for (var controller in _markControllers) {
          controller.clear();
        }
      });
    } catch (e) {
      _showError('Error submitting marks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        title: const Text(
          'Enter Exam Marks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class: ${widget.grade} ${widget.className}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select Lesson',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              value: selectedLesson,
                              items: lessons.map((String item) {
                                return DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedLesson = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_students.isNotEmpty) ...[
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Enter Marks',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _students.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            _students[index]['name'],
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: _markControllers[index],
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            decoration: InputDecoration(
                                              hintText: 'Mark',
                                              filled: true,
                                              fillColor: Colors.grey.shade100,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitMarks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text(
                          "Submit Marks",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
