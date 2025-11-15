// lib/screens/login_or_register.dart

import 'package:flutter/material.dart';
import 'package:mi_punto_de_venta/screens/login_page.dart';
import 'package:mi_punto_de_venta/screens/register_page.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  // Inicialmente, mostramos la página de login
  bool showLoginPage = true;

  // Función para cambiar de página
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      // Si 'showLoginPage' es true, muestra LoginPage
      // y le pasa la función 'togglePages' a su 'onTap'
      return LoginPage(onTap: togglePages);
    } else {
      // Si no, muestra RegisterPage
      // y le pasa la función 'togglePages' a su 'onTap'
      return RegisterPage(onTap: togglePages);
    }
  }
}