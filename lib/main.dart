import 'package:provider/provider.dart';
import 'package:mi_punto_de_venta/providers/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:mi_punto_de_venta/screens/auth_gate.dart';
import 'package:google_fonts/google_fonts.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => PosProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue, 
      brightness: Brightness.light,
    );

    final theme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      
      // Fuente Montserrat para look moderno
      textTheme: GoogleFonts.montserratTextTheme( 
        Theme.of(context).textTheme,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
      ),

      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
    ); 

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TechNorth', 
      theme: theme, 
      home: const AuthGate(),
    );
  }
}