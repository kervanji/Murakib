library default_connector;

import 'package:cloud_firestore/cloud_firestore.dart';

class DefaultConnector {
  static final DefaultConnector _instance = DefaultConnector._internal();
  late final FirebaseFirestore firestore;

  // Private constructor
  DefaultConnector._internal() {
    firestore = FirebaseFirestore.instance;
    _initializeFirestore();
  }

  static DefaultConnector get instance => _instance;

  void _initializeFirestore() {
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Example methods for data operations
  Future<DocumentReference> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      return await firestore.collection(collection).add(data);
    } catch (e) {
      print('Error adding document: $e');
      rethrow;
    }
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      print('Error updating document: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    try {
      return await firestore.collection(collection).doc(docId).get();
    } catch (e) {
      print('Error getting document: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot> queryCollection(String collection, {
    String? field,
    dynamic value,
  }) async {
    try {
      if (field != null && value != null) {
        return await firestore
            .collection(collection)
            .where(field, isEqualTo: value)
            .get();
      }
      return await firestore.collection(collection).get();
    } catch (e) {
      print('Error querying collection: $e');
      rethrow;
    }
  }
}
