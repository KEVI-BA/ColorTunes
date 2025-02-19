// registration_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Controladores para el registro con email
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createUserDocument(User user, String provider) async {
    final String joinedAt =
        DateFormat("d 'de' MMMM 'de' yyyy, hh:mm:ss a").format(DateTime.now());

    await _firestore.collection('users').doc(user.uid).set({
      'displayName': user.displayName ?? _displayNameController.text.trim(),
      'email': user.email,
      'followers': [],
      'following': [],
      'joined_at': joinedAt,
      'photoURL': user.photoURL ?? "llll",
      'posts': [],
      'provider': provider,
    });
  }

  /// Registra al usuario usando email y password.
  Future<void> _registerWithEmail() async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Actualiza el displayName si se proporcionó
      if (_displayNameController.text.trim().isNotEmpty) {
        await userCredential.user!
            .updateDisplayName(_displayNameController.text.trim());
      }

      // Crea el documento en Firestore
      await _createUserDocument(userCredential.user!, "email");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registro exitoso con Email")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Registra al usuario usando Google.
  Future<void> _registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // El usuario canceló el login.

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Crea el documento en Firestore
      await _createUserDocument(userCredential.user!, "google");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registro exitoso con Google")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error con Google: $e")),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Formulario para registro con email
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: "Display Name"),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _registerWithEmail,
                child: const Text("Registrarse con Email"),
              ),
              const Divider(height: 32),
              // Botón para registro con Google
              ElevatedButton(
                onPressed: _registerWithGoogle,
                child: const Text("Registrarse con Google"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
