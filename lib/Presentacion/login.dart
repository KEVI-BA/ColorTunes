import 'package:colortunes_beta/Presentacion/Feed.dart';
import 'package:colortunes_beta/Negocio/googleSignProvider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5A2EE8), Color(0xFF42D1FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            // Permite el desplazamiento cuando el teclado está visible
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "ColorTunes",
                  style: TextStyle(
                    fontFamily: 'Bigail',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Tarjeta con campos de entrada
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Campo Email
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email,
                                color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Campo Contraseña
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock,
                                color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),

                        // Botón de inicio de sesión con Email
                        ElevatedButton(
                          onPressed: _handleSignInWithEmail,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Iniciar sesión con Email",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Bigail',
                                    color: Color.fromARGB(255, 255, 255, 255)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Enlace de inicio de sesión con Google
                GestureDetector(
                  onTap: _handleSignInWithGoogle,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_translate_rounded,
                          color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        "Iniciar sesión con Google",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Bigail',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _handleSignInWithApple,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple,
                          color: Colors.white, size: 24), // Ícono de Apple
                      SizedBox(width: 8),
                      Text(
                        "Iniciar sesión con Apple",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Bigail',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Redirige a la pantalla principal cuando el usuario inicia sesión.
  void _navigateToFeed(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MusicSearchPage(user: user)),
    );
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
        const SnackBar(content: Text('Error al inciar sesión')),
      );
    }
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

  Future<void> _handleSignInWithApple() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Inicio de sesión con Apple no implementado')),
    );
  }
}
