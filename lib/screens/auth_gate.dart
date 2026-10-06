import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: CircularProgressIndicator(color: AppColors.maroon)),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // Verify that a staff/{uid} document exists in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('staff').doc(user.uid).get(),
          builder: (context, staffSnapshot) {
            if (staffSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.cream,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.maroon),
                      SizedBox(height: 16),
                      Text(
                        'Verifying staff credentials...',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (staffSnapshot.hasError || !staffSnapshot.hasData || !staffSnapshot.data!.exists) {
              // Unauthorized user: sign out immediately and return to login
              AuthService().signOut();
              return const LoginScreen();
            }

            // Authorized staff member: subscribe to admin orders topic
            FirebaseMessaging.instance.subscribeToTopic('admin_orders').catchError((e) {
              debugPrint('Error subscribing to admin_orders: $e');
            });

            return const HomeShell();
          },
        );
      },
    );
  }
}
