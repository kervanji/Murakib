import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:murakib_vip/services/firebase_service.dart';
import 'package:murakib_vip/admin/admin_home_page.dart';
import 'package:murakib_vip/teacher/teacher_home_page.dart';
import 'package:murakib_vip/students/student_home_page.dart';
import 'package:murakib_vip/principle/home_page.dart';
import '../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService _firebase = FirebaseService.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedSchool;
  List<String> _schoolNames = [];
  String _selectedRole = 'Students'; // Default role
  bool _isLoading = false;
  bool _rememberMe = false;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  final List<String> _roles = ['Students', 'Teacher', 'Principal', 'Admin'];

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadSchoolNames();
  }

  Future<void> _loadSchoolNames() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        List<String> schools = [];
        if (_selectedRole == 'Students') {
          final students = await _firebase.getStudents();
          schools = students.map((student) => student['school'] as String).toSet().toList();
        } else if (_selectedRole == 'Teacher' || _selectedRole == 'Principal') {
          final teachers = await _firebase.getTeachers();
          schools = teachers.map((teacher) => teacher['school'] as String).toSet().toList();
        }
        
        if (mounted) {
          setState(() {
            _schoolNames = schools..sort();
            _isLoading = false;
          });
        }
        return; // Success, exit the retry loop
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          if (mounted) {
            _showMessage('Loading schools failed, retrying... (Attempt $retryCount of $maxRetries)');
          }
          await Future.delayed(retryDelay);
        } else {
          if (mounted) {
            _showMessage('Failed to load schools after $maxRetries attempts. Please try again later.');
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _rememberMe = prefs.getBool('rememberMe') ?? false;
        if (_rememberMe) {
          _usernameController.text = prefs.getString('username') ?? '';
          _passwordController.text = prefs.getString('password') ?? '';
          _selectedRole = prefs.getString('role') ?? 'Students';
          _selectedSchool = prefs.getString('school') ?? '';
        }
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('username', _usernameController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setString('role', _selectedRole);
      await prefs.setString('school', _selectedSchool ?? '');
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.clear();
    }
  }

  Future<void> _attemptLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        _showMessage('Username, Password, and School are required.');
      }
      return;
    }
    if (_passwordController.text.length < 8 || _passwordController.text.length > 16) {
      if (mounted) {
        _showMessage('Password must be between 8-16 characters.');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      bool isAuthenticated = false;
      
      if (_selectedRole == 'Students') {
        final students = await _firebase.queryCollection(
          collection: 'students', 
          field: 'username', 
          value: _usernameController.text
        );
        isAuthenticated = students.any((student) =>
            student['password'] == _passwordController.text &&
            student['school'] == _selectedSchool);
        if (isAuthenticated && mounted) {
          await _saveCredentials();
          _navigateTo(StudentHomePage(studentUsername: _usernameController.text));
        }
      } else if (_selectedRole == 'Teacher') {
        final teachers = await _firebase.queryCollection(
          collection: 'teachers', 
          field: 'username', 
          value: _usernameController.text
        );
        isAuthenticated = teachers.any((teacher) =>
            teacher['password'] == _passwordController.text &&
            teacher['school'] == _selectedSchool);
        if (isAuthenticated && mounted) {
          await _saveCredentials();
          _navigateTo(TeacherHomePage(teacherUsername: _usernameController.text));
        }
      } else if (_selectedRole == 'Principal') {
        final principals = await _firebase.queryCollection(
          collection: 'principals', 
          field: 'username', 
          value: _usernameController.text
        );
        isAuthenticated = principals.any((principal) =>
            principal['password'] == _passwordController.text &&
            principal['school'] == _selectedSchool);
        if (isAuthenticated && mounted) {
          await _saveCredentials();
          _navigateTo(HomePage(
            principalUsername: _usernameController.text,
          ));
        }
      } else if (_selectedRole == 'Admin') {
        // Admin credentials
        isAuthenticated = _usernameController.text == 'kervanji' &&
            _passwordController.text == 'inoue133';
        if (isAuthenticated && mounted) {
          await _saveCredentials();
          _navigateTo(const AdminHomePage());
        }
      }

      if (mounted) {
        if (isAuthenticated) {
          _showMessage('Login successful as $_selectedRole');
        } else {
          _showMessage('Invalid credentials or school.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error during login: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return; // Prevent multiple simultaneous attempts

    setState(() {
      _isLoading = true;
    });

    int retryCount = 0;
    const maxRetries = 2;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final userCredential = await _googleAuthService.signInWithGoogle();
        
        if (userCredential != null && userCredential.user != null) {
          final user = userCredential.user!;
          debugPrint('Google Sign In successful: ${user.email}');
          
          // Check if the user exists in your database
          bool userFound = false;
          
          try {
            final teachers = await _firebase.queryCollection(
              collection: 'teachers',
              field: 'email',
              value: user.email,
            );
            
            if (teachers.isNotEmpty) {
              _navigateTo(TeacherHomePage(teacherUsername: teachers.first['username']));
              userFound = true;
            } else {
              final principals = await _firebase.queryCollection(
                collection: 'principals',
                field: 'email',
                value: user.email,
              );
              
              if (principals.isNotEmpty) {
                _navigateTo(HomePage(principalUsername: principals.first['username']));
                userFound = true;
              } else {
                final students = await _firebase.queryCollection(
                  collection: 'students',
                  field: 'email',
                  value: user.email,
                );
                
                if (students.isNotEmpty) {
                  _navigateTo(StudentHomePage(studentUsername: students.first['username']));
                  userFound = true;
                }
              }
            }
            
            if (!userFound) {
              _showMessage('No account found for this Google account. Please register first.');
              await _googleAuthService.signOut();
            }
            
            return; // Success, exit the retry loop
            
          } catch (dbError) {
            debugPrint('Database error: $dbError');
            throw dbError; // Propagate the error to trigger retry
          }
        }
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          _showMessage('Sign in failed, retrying... (Attempt $retryCount of $maxRetries)');
          await Future.delayed(retryDelay);
        } else {
          _showMessage('Failed to sign in after $maxRetries attempts. Please try again later.');
          await _googleAuthService.signOut();
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/murakib_logo.png',
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Monitor, Manage, Empower',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 32),

                  // Role Dropdown
                  DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (mounted) {
                        setState(() {
                          _selectedRole = value!;
                          _selectedSchool = ''; // Reset selected school
                          _loadSchoolNames(); // Reload schools for new role
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // School Dropdown
                  if (_selectedRole != 'Admin')
                    DropdownButtonFormField<String>(
                      value: _selectedSchool,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select School',
                        border: OutlineInputBorder(),
                      ),
                      items: _schoolNames.map((school) {
                        return DropdownMenuItem(
                          value: school,
                          child: Text(school),
                        );
                      }).toList(),
                      validator: (value) {
                        if (_selectedRole != 'Admin' && (value == null || value.isEmpty)) {
                          return 'Please select a school';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _selectedSchool = value;
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 16),

                  // Username Input
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username or Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8 || value.length > 16) {
                        return 'Password must be between 8-16 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Remember Me and Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              if (mounted) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              }
                            },
                          ),
                          const Text('Remember Me'),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          if (mounted) {
                            _showMessage('Forgot Password clicked');
                          }
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _attemptLogin();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Log In'),
                        ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer
                  const Text(
                    'Powered by [Kervanji]',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
