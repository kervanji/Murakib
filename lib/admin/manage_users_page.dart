import 'package:flutter/material.dart';
import 'package:murakib_vip/services/firebase_service.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final FirebaseService _firebase = FirebaseService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _selectedRole = 'All';
  String _searchQuery = '';
  final List<String> _roles = ['All', 'Teacher', 'Student', 'Principal'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      
      List<Map<String, dynamic>> users = [];
      if (_selectedRole == 'All' || _selectedRole == 'Teacher') {
        final teachers = await _firebase.getTeachers();
        users.addAll(teachers);
      }
      if (_selectedRole == 'All' || _selectedRole == 'Student') {
        final students = await _firebase.getStudents();
        users.addAll(students);
      }
      if (_selectedRole == 'All' || _selectedRole == 'Principal') {
        final principals = await _firebase.getPrincipals();
        users.addAll(principals);
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        users = users.where((user) {
          final name = user['name'].toString().toLowerCase();
          final username = user['username'].toString().toLowerCase();
          final school = user['school'].toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          return name.contains(query) || 
                 username.contains(query) || 
                 school.contains(query);
        }).toList();
      }

      // Sort by creation date
      users.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    try {
      final role = user['role'].toString().toLowerCase();
      final username = user['username'];

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete user "$username"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Delete user based on role
      switch (role) {
        case 'teacher':
          await _firebase.deleteTeacher(username);
          break;
        case 'student':
          await _firebase.deleteStudent(username);
          break;
        case 'principal':
          await _firebase.deletePrincipal(username);
          break;
        default:
          throw Exception('Invalid role: $role');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRole = value!);
                      _loadUsers();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(user['role']),
                                child: Text(user['name'][0].toUpperCase()),
                              ),
                              title: Text(user['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Username: ${user['username']}'),
                                  Text('School: ${user['school']}'),
                                  Text(
                                    'Role: ${user['role']}',
                                    style: TextStyle(
                                      color: _getRoleColor(user['role']),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(user),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'principal':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
