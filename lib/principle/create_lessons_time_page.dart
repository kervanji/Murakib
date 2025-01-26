import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateLessonsTimePage extends StatefulWidget {
  final String principalUsername;

  const CreateLessonsTimePage({super.key, required this.principalUsername});

  @override
  _CreateLessonsTimePageState createState() => _CreateLessonsTimePageState();
}

class _CreateLessonsTimePageState extends State<CreateLessonsTimePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _lessonNameController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedDay;
  String? _selectedGrade;
  String? _selectedClass;
  bool _isLoading = false;
  List<String> _grades = [];
  List<String> _classes = [];

  final List<String> _daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

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
        _grades =
            gradesSnapshot.docs.map((doc) => doc['name'] as String).toList();
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
      final classesSnapshot = await _firestore
          .collection('classes')
          .where('grade', isEqualTo: grade)
          .get();
      setState(() {
        _classes =
            classesSnapshot.docs.map((doc) => doc['name'] as String).toList();
        _selectedClass = null;
      });
    } catch (e) {
      _showError('Error loading classes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _createLesson() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime == null || _endTime == null) {
      _showError('Please select both start and end times');
      return;
    }

    if (_selectedDay == null ||
        _selectedGrade == null ||
        _selectedClass == null) {
      _showError('Please select day, grade, and class');
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

      // Check for time conflict
      final existingLessons = await _firestore
          .collection('lessons')
          .where('dayOfWeek', isEqualTo: _selectedDay)
          .get();

      for (var doc in existingLessons.docs) {
        final lesson = doc.data();
        if (lesson['grade'] == _selectedGrade &&
            lesson['class'] == _selectedClass &&
            _isTimeConflict(
              lesson['startTime'],
              lesson['endTime'],
              _timeOfDayToString(_startTime!),
              _timeOfDayToString(_endTime!),
            )) {
          _showError('Time conflict with existing lesson');
          return;
        }
      }

      // Add lesson
      await _firestore.collection('lessons').add({
        'lessonName': _lessonNameController.text.trim(),
        'teacherName': _teacherNameController.text.trim(),
        'startTime': _timeOfDayToString(_startTime!),
        'endTime': _timeOfDayToString(_endTime!),
        'dayOfWeek': _selectedDay,
        'grade': _selectedGrade,
        'class': _selectedClass,
        'school': school,
        'createdBy': widget.principalUsername,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _showSuccess('Lesson created successfully');
      _clearForm();
    } catch (e) {
      _showError('Error creating lesson: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isTimeConflict(String existingStart, String existingEnd,
      String newStart, String newEnd) {
    final existing1 = _parseTimeString(existingStart);
    final existing2 = _parseTimeString(existingEnd);
    final new1 = _parseTimeString(newStart);
    final new2 = _parseTimeString(newEnd);

    return (new1.isBefore(existing2) && new2.isAfter(existing1));
  }

  DateTime _parseTimeString(String time) {
    final parts = time.split(':');
    return DateTime(2024, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _clearForm() {
    _lessonNameController.clear();
    _teacherNameController.clear();
    setState(() {
      _startTime = null;
      _endTime = null;
      _selectedDay = null;
      _selectedGrade = null;
      _selectedClass = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          'Create Lesson Schedule',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _lessonNameController,
                      decoration: const InputDecoration(
                        labelText: 'Lesson Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter lesson name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _teacherNameController,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter teacher name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Day of Week',
                        border: OutlineInputBorder(),
                      ),
                      items: _daysOfWeek.map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectStartTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_startTime == null
                                ? 'Start Time'
                                : _timeOfDayToString(_startTime!)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectEndTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_endTime == null
                                ? 'End Time'
                                : _timeOfDayToString(_endTime!)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
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
                          value: grade,
                          child: Text(grade),
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
                      onChanged: _selectedGrade == null
                          ? null
                          : (value) {
                              setState(() {
                                _selectedClass = value;
                              });
                            },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createLesson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Create Lesson',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }

  @override
  void dispose() {
    _lessonNameController.dispose();
    _teacherNameController.dispose();
    super.dispose();
  }
}
