import 'package:colortunes_beta/Presentacion/login.dart';
import 'package:colortunes_beta/Presentacion/register.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColorTunes',
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
