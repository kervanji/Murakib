import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDocumentsPage extends StatefulWidget {
  final String principalUsername;

  const AddDocumentsPage({super.key, required this.principalUsername});

  @override
  _AddDocumentsPageState createState() => _AddDocumentsPageState();
}

class _AddDocumentsPageState extends State<AddDocumentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _selectedFile;
  String? _selectedGrade;
  String? _selectedClass;
  bool _isLoading = false;
  List<String> _grades = [];
  List<String> _classes = [];
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
    _loadDocuments();
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

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final principals = await _firestore
          .collection('principals')
          .where('username', isEqualTo: widget.principalUsername)
          .get();

      if (principals.docs.isEmpty) {
        _showError('Principal information not found');
        return;
      }

      final school = principals.docs.first['school'];

      final documentsSnapshot = await _firestore
          .collection('documents')
          .where('school', isEqualTo: school)
          .get();

      setState(() {
        _documents = documentsSnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      _showError('Error loading documents: $e');
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'doc', 'docx', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print('File picking error: $e');
      _showError('Error picking file: $e');
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      _showError('Please select a file');
      return;
    }

    if (_selectedGrade == null || _selectedClass == null) {
      _showError('Please select both grade and class');
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

      // Upload file to Firebase Storage
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}';
      final storageRef =
          FirebaseStorage.instance.ref().child('documents/$school/$fileName');

      final uploadTask = storageRef.putFile(_selectedFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Add document metadata to Firestore
      final documentData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'grade': _selectedGrade,
        'class': _selectedClass,
        'school': school,
        'uploadedBy': widget.principalUsername,
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': await _selectedFile!.length(),
      };

      await _firestore.collection('documents').add(documentData);

      if (!mounted) return;
      _showSuccess('Document uploaded successfully');
      _clearForm();
      _loadDocuments();
    } catch (e) {
      _showError('Error uploading document: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openDocument(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        _showError('Could not launch document');
      }
    } catch (e) {
      _showError('Error opening document: $e');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedFile = null;
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Text(
            'Documents',
            style: TextStyle(color: Colors.white),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upload Document'),
              Tab(text: 'View Documents'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Upload Document Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Document Title',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter document title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter description';
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
                          ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: Text(_selectedFile == null
                                ? 'Select Document (Excel/Word)'
                                : 'Selected: ${_selectedFile!.path.split('/').last}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _uploadDocument,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Upload Document',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

            // View Documents Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                    ? const Center(child: Text('No documents found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final document = _documents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              title: Text(
                                document['title'] ?? 'Untitled Document',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(document['description'] ?? ''),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Grade: ${document['grade']}, Class: ${document['class']}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () =>
                                    _openDocument(document['fileUrl']),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
        backgroundColor: const Color(0xFFFDF1E5),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
