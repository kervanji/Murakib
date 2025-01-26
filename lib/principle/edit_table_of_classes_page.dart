import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTableOfClassesPage extends StatefulWidget {
  final String principalUsername;

  const EditTableOfClassesPage({super.key, required this.principalUsername});

  @override
  _EditTableOfClassesPageState createState() => _EditTableOfClassesPageState();
}

class _EditTableOfClassesPageState extends State<EditTableOfClassesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _classController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _grades = [];
  String? _selectedGrade;

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
                  'id': doc.id,
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

  Future<void> _addGrade() async {
    if (!_formKey.currentState!.validate()) return;

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

      // Check if grade already exists
      final existingGrades = await _firestore
          .collection('grades')
          .where('name', isEqualTo: _gradeController.text.trim())
          .get();

      if (existingGrades.docs.isNotEmpty) {
        _showError('Grade already exists');
        return;
      }

      // Add grade
      await _firestore.collection('grades').add({
        'name': _gradeController.text.trim(),
        'school': school,
        'classes': [],
        'createdBy': widget.principalUsername,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _showSuccess('Grade added successfully');
      _gradeController.clear();
      _loadGrades();
    } catch (e) {
      _showError('Error adding grade: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addClass() async {
    if (_selectedGrade == null) {
      _showError('Please select a grade');
      return;
    }

    if (_classController.text.isEmpty) {
      _showError('Please enter class name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final grade = _grades.firstWhere((g) => g['name'] == _selectedGrade);
      final classes = List<String>.from(grade['classes']);

      if (classes.contains(_classController.text.trim())) {
        _showError('Class already exists in this grade');
        return;
      }

      classes.add(_classController.text.trim());

      // Update grade with new class
      await _firestore
          .collection('grades')
          .doc(grade['id'])
          .update({'classes': classes});

      _showSuccess('Class added successfully');
      _classController.clear();
      _loadGrades();
    } catch (e) {
      _showError('Error adding class: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGrade(String gradeId, String gradeName) async {
    try {
      // Check if there are any students in this grade
      final students = await _firestore
          .collection('students')
          .where('grade', isEqualTo: gradeName)
          .get();

      if (students.docs.isNotEmpty) {
        _showError('Cannot delete grade with existing students');
        return;
      }

      await _firestore.collection('grades').doc(gradeId).delete();

      _showSuccess('Grade deleted successfully');
      _loadGrades();
    } catch (e) {
      _showError('Error deleting grade: $e');
    }
  }

  Future<void> _deleteClass(
      String gradeId, List<String> classes, String className) async {
    try {
      // Check if there are any students in this class
      final students = await _firestore
          .collection('students')
          .where('class', isEqualTo: className)
          .get();

      if (students.docs.isNotEmpty) {
        _showError('Cannot delete class with existing students');
        return;
      }

      classes.remove(className);
      await _firestore
          .collection('grades')
          .doc(gradeId)
          .update({'classes': classes});

      _showSuccess('Class deleted successfully');
      _loadGrades();
    } catch (e) {
      _showError('Error deleting class: $e');
    }
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
          'Edit Table of Classes',
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
                    // Add Grade Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Add New Grade',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _gradeController,
                              decoration: const InputDecoration(
                                labelText: 'Grade Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter grade name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _addGrade,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Add Grade',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Add Class Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Add New Class',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedGrade,
                              decoration: const InputDecoration(
                                labelText: 'Select Grade',
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
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _classController,
                              decoration: const InputDecoration(
                                labelText: 'Class Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter class name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _addClass,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Add Class',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // List of Grades and Classes
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Grades and Classes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _grades.length,
                              itemBuilder: (context, index) {
                                final grade = _grades[index];
                                return ExpansionTile(
                                  title: Row(
                                    children: [
                                      Text(grade['name'] as String),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteGrade(
                                          grade['id'] as String,
                                          grade['name'] as String,
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          (grade['classes'] as List).length,
                                      itemBuilder: (context, classIndex) {
                                        final className = grade['classes']
                                            [classIndex] as String;
                                        return ListTile(
                                          title: Text(className),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteClass(
                                              grade['id'] as String,
                                              List<String>.from(
                                                  grade['classes']),
                                              className,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
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
    _gradeController.dispose();
    _classController.dispose();
    super.dispose();
  }
}
