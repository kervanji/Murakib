import 'package:flutter/material.dart';
import 'create_account_page.dart';
import 'manage_users_page.dart';
import 'package:murakib_vip/login/login_screen.dart';
import 'package:murakib_vip/services/firebase_service.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final FirebaseService _firebase = FirebaseService.instance;
  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalSchools = 0;
  List<Map<String, dynamic>> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final teachers = await _firebase.getTeachers();
      final students = await _firebase.getStudents();
      final principals = await _firebase.getPrincipals();
      final schools = await _firebase.getSchoolNames();
      
      // Get recent users (last 5)
      final allUsers = [...teachers, ...students, ...principals];
      allUsers.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
      
      if (mounted) {
        setState(() {
          _totalUsers = teachers.length + students.length + principals.length;
          _totalSchools = schools.length;
          _recentUsers = allUsers.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              // Add settings functionality here
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Users',
                          _totalUsers.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Total Schools',
                          _totalSchools.toString(),
                          Icons.school,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Recent Users Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Users',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._recentUsers.map((user) => ListTile(
                                leading: CircleAvatar(
                                  child: Text(user['name'][0].toUpperCase()),
                                ),
                                title: Text(user['name']),
                                subtitle: Text(user['role']),
                                trailing: Text(
                                  _formatDate(user['createdAt']),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateAccountPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Create Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ManageUsersPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.manage_accounts),
                          label: const Text('Manage Users'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
