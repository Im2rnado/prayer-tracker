import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'database_provider.dart';

// ── Auth state (Firebase User stream) ────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ── Current app user (Firestore document, live) ───────────────────────────────
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final firebaseUser = authAsync.value;
  if (firebaseUser == null) return Stream.value(null);
  return ref.watch(databaseProvider).streamUser(firebaseUser.uid);
});

// ── Auth service ──────────────────────────────────────────────────────────────
final authServiceProvider = Provider((ref) => AuthService(ref));

class AuthService {
  final Ref ref;
  AuthService(this.ref);

  Future<void> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final newUser = UserModel(
      uid: uid,
      email: email.trim(),
      name: name.trim(),
      role: role,
      inviteCode: role == UserRole.guardian ? _generateInviteCode() : null,
    );

    await ref.read(databaseProvider).createUser(newUser);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  /// Generates a 6-character alphanumeric code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
    final ts = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    int n = ts;
    for (int i = 0; i < 6; i++) {
      code += chars[n % chars.length];
      n ~/= chars.length;
    }
    return code;
  }
}
