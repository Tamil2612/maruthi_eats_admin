import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _subscribedUid;

  void _onStaffVerified(User user) {
    if (_subscribedUid != user.uid) {
      _subscribedUid = user.uid;
      FirebaseMessaging.instance.subscribeToTopic('admin_orders').catchError((e) {
        debugPrint('Error subscribing to admin_orders: $e');
      });
    }
  }

  void _onLoggedOut() {
    if (_subscribedUid != null) {
      _subscribedUid = null;
      FirebaseMessaging.instance.unsubscribeFromTopic('admin_orders').catchError((e) {
        debugPrint('Error unsubscribing from admin_orders: $e');
      });
    }
  }

  void _handleUnauthorized() {
    _onLoggedOut();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthService().signOut();
    });
  }

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
          _onLoggedOut();
          return const LoginScreen();
        }

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
              _handleUnauthorized();
              return const LoginScreen();
            }

            // Authorized staff member
            _onStaffVerified(user);

            return const HomeShell();
          },
        );
      },
    );
  }
}
