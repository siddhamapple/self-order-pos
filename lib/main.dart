import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'menu_screen.dart';
import 'kitchen_screen.dart';
import 'admin_home.dart';
import 'login_screen.dart';
import 'customer_queue_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');

  const firebaseOptions = FirebaseOptions(
    apiKey: firebaseApiKey,
    authDomain: "laphing-pos.firebaseapp.com",
    projectId: "laphing-pos",
    storageBucket: "laphing-pos.firebasestorage.app",
    messagingSenderId: "256918800064",
    appId: "1:256918800064:web:beffe713f4698361be8f25",
  );

  await Firebase.initializeApp(options: firebaseOptions);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laphing POS',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        // 🌑 GLOBAL DARK BACKGROUND
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E0E0E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        // ✅ FIXED DIALOG COLORS (BLACK ON WHITE)
        dialogTheme: const DialogThemeData(
  backgroundColor: Colors.white,
  titleTextStyle: TextStyle(
    color: Colors.black,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
  contentTextStyle: TextStyle(
    color: Colors.black,
    fontSize: 16,
  ),
),


        // ✅ TEXT THEME (FIXED TYPO)
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(
            color: Color(0xFFFFC94A), // Yellow accent
            fontWeight: FontWeight.bold,
          ),
        ),

        // 🔴 BUTTON THEME
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFE53935), // RED
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // 🔁 CHOOSE HOME PER BUILD (ONLY ONE UNCOMMENTED)
      home: const MenuScreen(), // CUSTOMER TABLET
   //   home: const KitchenScreen(), // KITCHEN
   //    home: const CustomerQueueScreen(), // QUEUE DISPLAY
   //   home: const AuthGate(), // ADMIN
    );
  }
}

/// 🔐 ADMIN AUTH GATE (UNCHANGED LOGIC)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _isKitchenUser(User user) {
    return user.email != null &&
        user.email!.toLowerCase().contains('kitchen');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        if (_isKitchenUser(user)) {
          return const KitchenScreen();
        }

        return const AdminHome();
      },
    );
  }
}
