import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RulePage extends StatefulWidget {
  final String principalUsername;

  const RulePage({super.key, required this.principalUsername});

  @override
  _RulePageState createState() => _RulePageState();
}

class _RulePageState extends State<RulePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _ruleController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _rules = [];

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rulesSnapshot = await _firestore
          .collection('rules')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _rules = rulesSnapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
      });
    } catch (e) {
      _showError('Error loading rules: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addRule() async {
    if (_ruleController.text.trim().isEmpty) {
      _showError('Please enter a rule');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('rules').add({
        'content': _ruleController.text.trim(),
        'createdBy': widget.principalUsername,
        'timestamp': DateTime.now().toIso8601String(),
        'isActive': true,
      });

      _ruleController.clear();
      await _loadRules();
    } catch (e) {
      _showError('Error adding rule: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRule(String ruleId, bool currentStatus) async {
    try {
      await _firestore.collection('rules').doc(ruleId).update({
        'isActive': !currentStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await _loadRules();
    } catch (e) {
      _showError('Error updating rule: $e');
    }
  }

  Future<void> _deleteRule(String ruleId) async {
    try {
      await _firestore.collection('rules').doc(ruleId).delete();
      await _loadRules();
    } catch (e) {
      _showError('Error deleting rule: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          'Rules',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRules,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ruleController,
                    decoration: const InputDecoration(
                      hintText: 'Enter new rule...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addRule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rules.isEmpty
                    ? const Center(child: Text('No rules added yet'))
                    : ListView.builder(
                        itemCount: _rules.length,
                        itemBuilder: (context, index) {
                          final rule = _rules[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: ListTile(
                              title: Text(
                                rule['content'],
                                style: TextStyle(
                                  decoration: rule['isActive'] == false
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                'Created by: ${rule['createdBy']}\n${DateTime.parse(rule['timestamp']).toLocal()}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: rule['isActive'] ?? true,
                                    onChanged: (bool value) {
                                      _toggleRule(rule['id'], rule['isActive']);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteRule(rule['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }

  @override
  void dispose() {
    _ruleController.dispose();
    super.dispose();
  }
}
