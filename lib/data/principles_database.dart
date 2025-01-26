import 'package:murakib_vip/services/firebase_service.dart';

class PrinciplesDatabase {
  static final PrinciplesDatabase _instance = PrinciplesDatabase._internal();
  final FirebaseService _firebase = FirebaseService.instance;

  PrinciplesDatabase._internal();
  static PrinciplesDatabase get instance => _instance;

  // Method to add a principal
  Future<void> addPrincipal({
    required String username,
    required String password,
    required String phone,
    required String school,
  }) async {
    try {
      // Check if username exists
      final existingPrincipals = await _firebase.queryCollection(
        collection: 'principals',
        field: 'username',
        value: username,
      );

      if (existingPrincipals.isNotEmpty) {
        throw Exception('Username already exists');
      }

      // Add principal to Firebase
      await _firebase.addPrincipal({
        'username': username,
        'password': password,
        'phone': phone,
        'school': school,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding principal: $e');
      rethrow;
    }
  }

  // Method to get all principals
  Future<List<Map<String, dynamic>>> getAllPrincipals() async {
    return await _firebase.getPrincipals();
  }

  // Method to get principal by username
  Future<Map<String, dynamic>?> getPrincipalByUsername(String username) async {
    final principals = await _firebase.queryCollection(
      collection: 'principals',
      field: 'username',
      value: username,
    );
    return principals.isNotEmpty ? principals.first : null;
  }

  // Method to get principal by school
  Future<Map<String, dynamic>?> getPrincipalBySchool(String school) async {
    final principals = await _firebase.queryCollection(
      collection: 'principals',
      field: 'school',
      value: school,
    );
    return principals.isNotEmpty ? principals.first : null;
  }

  // Method to update principal information
  Future<void> updatePrincipal(
      String principalId, Map<String, dynamic> updates) async {
    await _firebase.updateDocument('principals', principalId, updates);
  }

  // Method to remove a principal
  Future<void> removePrincipal(String username) async {
    final principals = await _firebase.queryCollection(
      collection: 'principals',
      field: 'username',
      value: username,
    );
    if (principals.isNotEmpty) {
      await _firebase.deleteDocument('principals', principals.first['id']);
    }
  }

  // Method to check if username exists
  Future<bool> usernameExists(String username) async {
    final principals = await _firebase.queryCollection(
      collection: 'principals',
      field: 'username',
      value: username,
    );
    return principals.isNotEmpty;
  }

  // Method to clear all principals
  Future<void> clearAll() async {
    final principals = await _firebase.getPrincipals();
    for (var principal in principals) {
      await _firebase.deleteDocument('principals', principal['id']);
    }
  }
}

// Access the singleton instance
final PrinciplesDatabase principlesDatabase = PrinciplesDatabase.instance;
