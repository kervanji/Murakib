import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:murakib_vip/firebase_options.dart';
import 'package:murakib_vip/login/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with explicit platform check
    if (const bool.fromEnvironment('dart.library.js_util')) {
      // Web platform
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.web,
      );
    } else {
      // Other platforms
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('Firebase initialized successfully');

    // Configure Firestore settings with explicit error handling
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('Firestore settings configured successfully');
    } catch (e) {
      debugPrint('Error configuring Firestore settings: $e');
    }

    // Initialize Firebase Storage with explicit error handling
    try {
      final storage = FirebaseStorage.instance;
      storage.setMaxUploadRetryTime(const Duration(seconds: 30));
      storage.setMaxOperationRetryTime(const Duration(seconds: 30));
      debugPrint('Firebase Storage initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase Storage: $e');
    }
  } on FirebaseException catch (e) {
    debugPrint('Firebase initialization error: ${e.code} - ${e.message}');
  } catch (e) {
    debugPrint('Unexpected error during Firebase initialization: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Murakib',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDF1E5),
      ),
      home: const LoginScreen(),
    );
  }
}
