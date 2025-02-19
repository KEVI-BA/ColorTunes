import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inicia sesión con Google y retorna el usuario autenticado o null si falla.
  Future<User?> signInWithGoogle() async {
    try {
      // Inicia el flujo de autenticación.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión.
        return null;
      }

      // Obtiene la autenticación del usuario.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crea las credenciales de Firebase.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Realiza el sign-in en Firebase.
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (error) {
      debugPrint('Error en signInWithGoogle: $error');
      return null;
    }
  }

  /// Cierra la sesión tanto en Google como en Firebase.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (error) {
      debugPrint('Error en signOut: $error');
    }
  }
}
