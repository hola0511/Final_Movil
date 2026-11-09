
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  User? get usuarioActual => _auth.currentUser;

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    UserCredential? credencial;

    try {
      credencial = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credencial.user!.uid;

      await _db.collection('usuarios').doc(uid).set({
        'nombre': nombre.trim(),
        'email': email.trim(),
        'rol': 'participante',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Una cuenta puede existir aunque falle la creación
      // de su perfil. Se conserva para recuperación.
      rethrow;
    }
  }

  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      perfilActual(String uid) {
    return _db.collection('usuarios').doc(uid).snapshots();
  }
}
