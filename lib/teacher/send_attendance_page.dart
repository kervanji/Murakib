import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendAttendancePage extends StatefulWidget {
  final String teacherUsername;
  final String grade;
  final String className;

  const SendAttendancePage({
    super.key,
    required this.teacherUsername,
    required this.grade,
    required this.className,
  });

  @override
  _SendAttendancePageState createState() => _SendAttendancePageState();
}

class _SendAttendancePageState extends State<SendAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _students = [];
  List<bool> _selectedStudents = [];
  int _totalStudents = 0;
  bool _isLoading = true;
  bool _isSending = false;
  String? _teacherSchool;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      // First get teacher's school
      final teacherDoc = await _firestore
          .collection('teachers')
          .where('username', isEqualTo: widget.teacherUsername)
          .get();

      if (teacherDoc.docs.isEmpty) {
        throw Exception('Teacher not found');
      }

      _teacherSchool = teacherDoc.docs.first['school'] as String;

      // Then get students
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('school', isEqualTo: _teacherSchool)
          .where('grade', isEqualTo: widget.grade)
          .where('class', isEqualTo: widget.className)
          .get();

      setState(() {
        _students = studentsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'username': data['username'] as String,
            'name': data['name'] as String,
          };
        }).toList();
        _selectedStudents = List.generate(_students.length, (_) => false);
        _totalStudents = _students.length;
      });
    } catch (e) {
      _showError('Error loading students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectAll() {
    setState(() {
      for (int i = 0; i < _selectedStudents.length; i++) {
        _selectedStudents[i] = true;
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _sendAttendance() async {
    if (_selectedStudents.every((selected) => !selected)) {
      _showError('Please select at least one student');
      return;
    }

    setState(() => _isSending = true);

    try {
      final batch = _firestore.batch();
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      // Create attendance collection document
      final attendanceDoc = _firestore.collection('attendance').doc();
      batch.set(attendanceDoc, {
        'date': timestamp,
        'grade': widget.grade,
        'class': widget.className,
        'school': _teacherSchool,
        'teacherUsername': widget.teacherUsername,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add student records
      for (int i = 0; i < _students.length; i++) {
        final studentRef =
            attendanceDoc.collection('students').doc(_students[i]['id']);
        batch.set(studentRef, {
          'studentId': _students[i]['id'],
          'username': _students[i]['username'],
          'status': _selectedStudents[i] ? 'Present' : 'Absent',
          'timestamp': timestamp,
        });
      }

      await batch.commit();

      if (!mounted) return;

      // Show success message
      final presentCount =
          _selectedStudents.where((selected) => selected).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance saved: $presentCount/${_students.length} students present',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back after successful save
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pop(context);
      });
    } catch (e) {
      _showError('Error saving attendance: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        title: Text(
          '${widget.grade} - ${widget.className}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(
                  child: Text(
                    'No students in this class',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final username = student['username'] as String;
                            final name = student['name'] as String;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey.shade800,
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(username),
                                trailing: Checkbox(
                                  value: _selectedStudents[index],
                                  onChanged: _isSending
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedStudents[index] = value!;
                                          });
                                        },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isSending ? null : _sendAttendance,
                            icon: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white),
                            label: Text(
                              _isSending ? "Saving..." : "Send",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 24.0,
                              ),
                            ),
                          ),
                          Text(
                            "$_totalStudents Students",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isSending ? null : _selectAll,
                            icon: const Icon(Icons.select_all,
                                color: Colors.white),
                            label: const Text(
                              "Select All",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 24.0,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
    );
  }
}
