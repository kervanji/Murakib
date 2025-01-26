import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SeeAttendancePage extends StatefulWidget {
  final String principalUsername;

  const SeeAttendancePage({super.key, required this.principalUsername});

  @override
  _SeeAttendancePageState createState() => _SeeAttendancePageState();
}

class _SeeAttendancePageState extends State<SeeAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _selectedGrade;
  String? _selectedClass;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _grades = [];
  List<String> _classes = [];
  List<Map<String, dynamic>> _attendance = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final gradesSnapshot = await _firestore.collection('grades').get();
      setState(() {
        _grades = gradesSnapshot.docs
            .map((doc) => {
                  'name': doc['name'] as String,
                  'classes': (doc['classes'] as List<dynamic>).cast<String>(),
                })
            .toList();
      });
    } catch (e) {
      _showError('Error loading grades: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClasses(String grade) async {
    setState(() => _isLoading = true);
    try {
      final selectedGrade = _grades.firstWhere((g) => g['name'] == grade);
      setState(() {
        _classes = List<String>.from(selectedGrade['classes']);
        _selectedClass = null;
      });
    } catch (e) {
      _showError('Error loading classes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendance();
    }
  }

  Future<void> _loadAttendance() async {
    if (_selectedGrade == null ||
        _selectedClass == null ||
        _selectedDate == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get principal's school
      final principals = await _firestore
          .collection('principals')
          .where('username', isEqualTo: widget.principalUsername)
          .get();

      if (principals.docs.isEmpty) {
        _showError('Principal information not found');
        return;
      }

      final school = principals.docs.first['school'];

      // Get attendance records
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('date',
              isEqualTo: DateFormat('yyyy-MM-dd').format(_selectedDate!))
          .where('school', isEqualTo: school)
          .where('grade', isEqualTo: _selectedGrade)
          .where('class', isEqualTo: _selectedClass)
          .get();

      setState(() {
        _attendance = attendanceSnapshot.docs
            .map((doc) => {
                  'studentName': doc['studentName'],
                  'status': doc['status'],
                  'time': doc['time'],
                })
            .toList();
      });
    } catch (e) {
      _showError('Error loading attendance: $e');
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
          'Attendance Records',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filters Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Select Filters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedGrade,
                            decoration: const InputDecoration(
                              labelText: 'Grade',
                              border: OutlineInputBorder(),
                            ),
                            items: _grades.map((grade) {
                              return DropdownMenuItem(
                                value: grade['name'] as String,
                                child: Text(grade['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGrade = value;
                                if (value != null) {
                                  _loadClasses(value);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(),
                            ),
                            items: _classes.map((className) {
                              return DropdownMenuItem(
                                value: className,
                                child: Text(className),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedClass = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : DateFormat('MMM dd, yyyy')
                                      .format(_selectedDate!),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Attendance Records
                  if (_attendance.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Attendance for ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _attendance.length,
                              itemBuilder: (context, index) {
                                final record = _attendance[index];
                                return ListTile(
                                  title: Text(record['studentName']),
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
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_selectedGrade != null &&
                      _selectedClass != null &&
                      _selectedDate != null) ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No attendance records found for the selected filters',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }
}
