import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mi_punto_de_venta/screens/pos_page.dart'; 
import 'package:mi_punto_de_venta/screens/login_or_register.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            // 2. Apuntar a la nueva PosPage
            return const PosPage(); 
          }
          else {
            return const LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}