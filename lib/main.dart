import 'package:colortunes_beta/Screens/login.dart';
import 'package:colortunes_beta/Screens/register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autenticación',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthScreen(),
    );
  }
}

/// Esta pantalla contiene las dos pestañas: Login y Registro.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dos pestañas: Iniciar sesión y Registrarse
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: const Center(
            child: Text(
              "¡Bienvenidos!",
              style: TextStyle(
                fontSize: 25,
                fontFamily: 'Bigail',
              ),
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Iniciar sesión"),
              Tab(text: "Registrarse"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LoginScreen(), // Pantalla para iniciar sesión
            RegistrationScreen(), // Pantalla para registrarse
          ],
        ),
      ),
    );
  }
}
