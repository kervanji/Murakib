import 'package:flutter/material.dart';
import 'package:murakib_vip/services/firebase_service.dart';
import 'package:murakib_vip/data/grade_and_classes_database.dart';

class AddStudentPage extends StatefulWidget {
  final String principalUsername;

  const AddStudentPage({super.key, required this.principalUsername});

  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final FirebaseService _firebase = FirebaseService.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedGrade;
  String? _selectedClass;
  List<String> _grades = [];
  List<String> _classes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGradesAndClasses();
  }

  Future<void> _loadGradesAndClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final grades = await GradeAndClassesDatabase.instance.getAllGrades();
      setState(() {
        _grades = grades;
      });
    } catch (e) {
      _showError('Error loading grades: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClassesForGrade(String grade) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final classes =
          await GradeAndClassesDatabase.instance.getClassesForGrade(grade);
      setState(() {
        _classes = classes;
        _selectedClass = null; // Reset selected class when grade changes
      });
    } catch (e) {
      _showError('Error loading classes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGrade == null || _selectedClass == null) {
      _showError('Please select both grade and class');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if username already exists
      final existingStudents = await _firebase.queryCollection(
        collection: 'students',
        field: 'username',
        value: _usernameController.text.trim(),
      );

      if (existingStudents.isNotEmpty) {
        _showError('Username already exists');
        return;
      }

      // Get principal's school
      final principals = await _firebase.queryCollection(
        collection: 'principals',
        field: 'username',
        value: widget.principalUsername,
      );

      if (principals.isEmpty) {
        _showError('Principal information not found');
        return;
      }

      final school = principals.first['school'];

      // Add student
      await _firebase.addStudent({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'grade': _selectedGrade,
        'class': _selectedClass,
        'school': school,
        'createdBy': widget.principalUsername,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _showSuccess('Student added successfully');
      _clearForm();
    } catch (e) {
      _showError('Error adding student: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _usernameController.clear();
    _passwordController.clear();
    _nameController.clear();
    _phoneController.clear();
    setState(() {
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
          'Add Student',
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
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
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
                            _loadClassesForGrade(value);
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
                      onPressed: _isLoading ? null : _addStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Add Student',
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
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
