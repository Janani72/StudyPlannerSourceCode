import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';
import '../storage_service.dart';
import 'firestore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;

  // ================= SIGN UP =================
  static Future<bool> signUp(
      String name,
      String email,
      String password,
      ) async {
    try {
      UserCredential credential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = credential.user;

      if (user == null) return false;

      // Update Firebase display name
      await user.updateDisplayName(name.trim());
      print("========== SIGNUP ==========");
      print("Name  : $name");
      print("Email : $email");
      print("Password : $password");

      await FirestoreService.saveUserProfile(
        user.uid,
        name.trim(),
        email.trim(),
      );


      // Save locally
      LocalUser localUser = LocalUser(
        name: name.trim(),
        email: email.trim(),
        password: password,
      );

      await StorageService.setUser(localUser);
      await StorageService.setLoggedIn(true);

      return true;
    } on FirebaseAuthException catch (e) {
      print("Firebase SignUp Error: ${e.code}");
      print(e.message);
      return false;
    } catch (e) {
      print("SignUp Error: $e");
      return false;
    }
  }

  // ================= LOGIN =================
  static Future<bool> login(String email, String password) async {
    try {
      UserCredential credential =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = credential.user;

      if (user == null) return false;

      await StorageService.setUser(
        LocalUser(
          name: user.displayName ?? "Student",
          email: user.email ?? email,
          password: password,
        ),
      );

      await StorageService.setLoggedIn(true);

      return true;
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.code}");
      print(e.message);
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // ================= CURRENT USER =================
  static Future<LocalUser?> getCurrentUser() async {
    User? user = _auth.currentUser;

    if (user == null) {
      return await StorageService.getUser();
    }

    return LocalUser(
      name: user.displayName ?? "Student",
      email: user.email ?? "",
      password: "",
    );
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    await _auth.signOut();

    await StorageService.setLoggedIn(false);

    await StorageService.setUser(
      LocalUser(
        name: '',
        email: '',
      ),
    );
  }

  // ================= LOGIN STATUS =================
  static Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // ================= UPDATE PROFILE =================
  static Future<bool> updateUser(LocalUser user) async {
    try {
      User? firebaseUser = _auth.currentUser;

      if (firebaseUser == null) return false;

      await firebaseUser.updateDisplayName(user.name);

      await FirestoreService.updateUserProfile(
        firebaseUser.uid,
        user.name,
      );

      await StorageService.setUser(user);

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // ================= RESET PASSWORD =================
  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // ================= CHANGE PASSWORD =================
  static Future<bool> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // ================= DELETE ACCOUNT =================
  static Future<bool> deleteAccount() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) return false;

      await FirestoreService.deleteUser(user.uid);

      await user.delete();

      await logout();

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}