import 'package:flutter/material.dart';
import 'package:murakib_vip/services/firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  CreateAccountPageState createState() => CreateAccountPageState();
}

class CreateAccountPageState extends State<CreateAccountPage> {
  final FirebaseService _firebase = FirebaseService.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _newSchoolController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _newSchoolFocus = FocusNode();

  String _selectedRole = 'Teacher';
  String? _selectedSchool;
  bool _isLoading = false;
  bool _isAddingNewSchool = false;
  List<String> _schools = [];

  final List<String> _roles = ['Teacher', 'Student', 'Principal'];

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final schools = await _firebase.getSchoolNames();
      setState(() {
        _schools = schools..sort();
      });
    } catch (e) {
      _showError('Error loading schools: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _newSchoolController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _newSchoolFocus.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    debugPrint('\n=== Starting Account Creation Process ===');
    debugPrint('Mounted state: $mounted');
    
    if (!mounted) {
      debugPrint('Widget not mounted, returning early');
      return;
    }

    // Validate input fields
    debugPrint('\n--- Validating Input Fields ---');
    if (_nameController.text.trim().isEmpty) {
      debugPrint('Error: Name is empty');
      _showError('Please enter a name');
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      debugPrint('Error: Username is empty');
      _showError('Please enter a username');
      return;
    }

    if (_passwordController.text.isEmpty) {
      debugPrint('Error: Password is empty');
      _showError('Please enter a password');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      debugPrint('Error: Passwords do not match');
      _showError('Passwords do not match');
      return;
    }

    if (_selectedSchool == null && !_isAddingNewSchool) {
      debugPrint('Error: No school selected and not adding new school');
      _showError('Please select a school');
      return;
    }

    if (_isAddingNewSchool && _newSchoolController.text.trim().isEmpty) {
      debugPrint('Error: New school name is empty');
      _showError('Please enter a school name');
      return;
    }

    debugPrint('\n--- Input Validation Passed ---');
    debugPrint('Name: ${_nameController.text.trim()}');
    debugPrint('Username: ${_usernameController.text.trim()}');
    debugPrint('Role: $_selectedRole');
    debugPrint('School: ${_isAddingNewSchool ? _newSchoolController.text.trim() : _selectedSchool}');
    debugPrint('Is Adding New School: $_isAddingNewSchool');

    if (mounted) {
      setState(() => _isLoading = true);
      debugPrint('Set loading state to true');
    }

    try {
      // Check if username already exists
      final collection = '${_selectedRole.toLowerCase()}s';
      debugPrint('\n--- Checking for Existing Username ---');
      debugPrint('Collection: $collection');
      debugPrint('Username to check: ${_usernameController.text.trim()}');
      
      final existingUsers = await _firebase.queryCollection(
        collection: collection,
        field: 'username',
        value: _usernameController.text.trim(),
      );
      
      debugPrint('Existing users found: ${existingUsers.length}');
      debugPrint('Existing users data: $existingUsers');

      if (existingUsers.isNotEmpty) {
        debugPrint('Error: Username already exists');
        if (mounted) {
          _showError('Username already exists');
          setState(() => _isLoading = false);
        }
        return;
      }
      debugPrint('Username check passed - no existing users found');

      // Add new school if needed
      String schoolName = _selectedSchool ?? '';
      if (_isAddingNewSchool) {
        debugPrint('\n--- Adding New School ---');
        final newSchoolName = _newSchoolController.text.trim();
        debugPrint('New school name: $newSchoolName');
        
        try {
          await _firebase.addSchool(newSchoolName);
          schoolName = newSchoolName;
          debugPrint('Successfully added new school: $newSchoolName');
        } catch (e) {
          debugPrint('Error adding school: $e');
          if (e is FirebaseException) {
            debugPrint('Firebase error code: ${e.code}');
            debugPrint('Firebase error message: ${e.message}');
          }
          if (mounted) {
            _showError('Failed to add new school: $e');
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      // Prepare user data
      debugPrint('\n--- Preparing User Data ---');
      final userData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
        'role': _selectedRole.toLowerCase(),
        'school': schoolName,
        'createdAt': DateTime.now().toIso8601String(),
      };
      debugPrint('User data prepared: $userData');

      // Add user to the appropriate collection
      debugPrint('\n--- Adding User to Collection ---');
      debugPrint('Target collection: $collection');
      
      try {
        switch (_selectedRole.toLowerCase()) {
          case 'teacher':
            debugPrint('Adding teacher...');
            await _firebase.addTeacher(userData);
            debugPrint('Teacher added successfully');
            break;
          case 'student':
            debugPrint('Adding student...');
            await _firebase.addStudent(userData);
            debugPrint('Student added successfully');
            break;
          case 'principal':
            debugPrint('Adding principal...');
            await _firebase.addPrincipal(userData);
            debugPrint('Principal added successfully');
            break;
          default:
            throw Exception('Invalid role selected: $_selectedRole');
        }

        debugPrint('\n=== Account Creation Successful ===');
        if (!mounted) {
          debugPrint('Widget not mounted after user creation');
          return;
        }
        _showSuccess('Account created successfully');
        _resetForm();
      } catch (e) {
        debugPrint('\n!!! Error Adding User !!!');
        debugPrint('Error details: $e');
        if (e is FirebaseException) {
          debugPrint('Firebase error code: ${e.code}');
          debugPrint('Firebase error message: ${e.message}');
        }
        if (mounted) {
          _showError('Failed to create user account: $e');
        }
      }
    } catch (e) {
      debugPrint('\n!!! Unexpected Error !!!');
      debugPrint('Error details: $e');
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      if (mounted) {
        _showError('Error creating account: $e');
      }
    } finally {
      debugPrint('\n--- Cleaning Up ---');
      if (mounted) {
        debugPrint('Setting loading state to false');
        setState(() => _isLoading = false);
      } else {
        debugPrint('Widget not mounted during cleanup');
      }
      debugPrint('=== Account Creation Process Completed ===\n');
    }
  }

  void _resetForm() {
    _nameController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _newSchoolController.clear();
    setState(() {
      _selectedRole = 'Teacher';
      _selectedSchool = null;
      _isAddingNewSchool = false;
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
        title: const Text('Create Account'),
      ),
      body: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          items: _roles.map((String role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {
                                _selectedRole = value!;
                                _selectedSchool = null;
                                _loadSchools();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus && mounted) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                          child: TextFormField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              if (mounted) {
                                _nameFocus.requestFocus();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus && mounted) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                          child: TextFormField(
                            controller: _usernameController,
                            focusNode: _usernameFocus,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              if (mounted) {
                                _usernameFocus.requestFocus();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus && mounted) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                          child: TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              if (mounted) {
                                _passwordFocus.requestFocus();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus && mounted) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocus,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              if (mounted) {
                                _confirmPasswordFocus.requestFocus();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_isAddingNewSchool) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedSchool,
                            decoration: InputDecoration(
                              labelText: 'School',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  if (mounted) {
                                    setState(() {
                                      _isAddingNewSchool = true;
                                      _selectedSchool = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            items: _schools.map((String school) {
                              return DropdownMenuItem<String>(
                                value: school,
                                child: Text(school),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (mounted) {
                                setState(() => _selectedSchool = value);
                              }
                            },
                          ),
                        ] else ...[
                          Focus(
                            onFocusChange: (hasFocus) {
                              if (!hasFocus && mounted) {
                                FocusScope.of(context).unfocus();
                              }
                            },
                            child: TextFormField(
                              controller: _newSchoolController,
                              focusNode: _newSchoolFocus,
                              decoration: InputDecoration(
                                labelText: 'New School Name',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    if (mounted) {
                                      setState(() {
                                        _isAddingNewSchool = false;
                                        _newSchoolController.clear();
                                      });
                                    }
                                  },
                                ),
                              ),
                              onTap: () {
                                if (mounted) {
                                  _newSchoolFocus.requestFocus();
                                }
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createAccount,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
