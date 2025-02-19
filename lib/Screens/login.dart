import 'package:colortunes_beta/Screens/Feed.dart';
import 'package:colortunes_beta/Screens/googleSignProvider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignInService _googleService = GoogleSignInService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Campo de Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              // Campo de Password
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Botón de inicio de sesión con Email
              ElevatedButton(
                onPressed: _handleSignInWithEmail,
                child: const Text('Iniciar sesión con Email'),
              ),
              const SizedBox(height: 16),

              // Botón de inicio de sesión con Google
              ElevatedButton(
                onPressed: _handleSignInWithGoogle,
                child: const Text('Iniciar sesión con Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Redirige a FeedScreen cuando el usuario inicia sesión correctamente.
  void _navigateToFeed(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MusicSearchPage(user: user)),
    );
  }

  /// Inicio de sesión con Google
  Future<void> _handleSignInWithGoogle() async {
    final user = await _googleService.signInWithGoogle();
    if (user != null) {
      _navigateToFeed(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar sesión con Google')),
      );
    }
  }

  /// Inicio de sesión con Email y Contraseña
  Future<void> _handleSignInWithEmail() async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _navigateToFeed(userCredential.user!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
