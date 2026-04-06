import 'package:firebase_auth/firebase_auth.dart';

/// Сервис аутентификации
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Поток состояния авторизации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Текущий пользователь
  User? get currentUser => _auth.currentUser;

  /// Проверка авторизации
  bool get isLoggedIn => _auth.currentUser != null;

  /// Вход по email и паролю
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Регистрация по email и паролю
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Восстановление пароля
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Смена пароля
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _auth.currentUser?.email;
    if (email == null) throw Exception('Пользователь не авторизован');

    // Re-authenticate
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await _auth.currentUser!.reauthenticateWithCredential(credential);
    await _auth.currentUser!.updatePassword(newPassword);
  }

  /// Выход
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Обновить email
  Future<void> updateEmail(String newEmail) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail.trim());
  }

  /// Удалить аккаунт
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}
