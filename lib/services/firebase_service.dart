import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ Sign-in function
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("Error signing in: $e");
      return null;
    }
  }

  // ✅ Sign-up function
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("Error signing up: $e");
      return null;
    }
  }

  // ✅ Sign-out function
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ✅ Save user messages to Firestore
  Future<void> saveChatMessage(String userId, String message, String response) async {
    await _db.collection("users").doc(userId).collection("chats").add({
      "message": message,
      "response": response,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  // ✅ Get user messages (used in `chat_screen.dart`)
  Stream<QuerySnapshot> getChatMessages(String userId) {
    return _db.collection("users").doc(userId).collection("chats").snapshots();
  }
}
