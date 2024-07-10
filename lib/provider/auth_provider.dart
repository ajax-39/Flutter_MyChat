import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //* check user already signin
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  //* Sign In
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);

    notifyListeners();
  }

  //* Sign Up
  // Future<void> signUp(
  //     String email, String password, String name, String imageUrl) async {
  //   UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
  //     email: email,
  //     password: password,
  //   );

  //   await _firestore.collection("users").doc(userCredential.user!.uid).set({
  //     "uid": userCredential.user!.uid,
  //     "name": name,
  //     "email": email,
  //     "imageUrl": imageUrl,
  //   });

  //   notifyListeners();
  // }

  //* Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
