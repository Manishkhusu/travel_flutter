import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up User
  Future<String> signUpUser({
    required String username,
    required String email,
    required String password,
    required String usertype,
    String? organization,
    String? phone,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Common User Data (Always Present)
        Map<String, dynamic> userData = {
          'username': username,
          'uid': credential.user!.uid,
          'email': email,
          'usertype': usertype,
          'bio': '', // Add default empty bio to avoid null issues.
        };

        // Add Organizer-Specific Fields (Only if applicable)
        if (usertype == 'Organizer') {
          if (organization != null && phone != null) {
            userData['organization'] = organization;
            userData['phone'] = phone;
          } else {
            return "Organization and phone are required for Organizer signup";
          }
        }

        // Firestore Data Store (Create the document for *all* users)
        await _firestore
            .collection("users")
            .doc(credential.user!.uid)
            .set(userData);

        res = "success";
      } else {
        res = "Please fill in all fields.";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        res = "This email is already in use. Try logging in.";
      } else if (e.code == 'weak-password') {
        res = "Password should be at least 6 characters.";
      } else {
        res = e.message ?? "An error occurred.";
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // Login User
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred!!!";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        res = 'success';
      } else {
        res = "Please enter all the fields.";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        res = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        res = "Incorrect password.";
      } else {
        res = e.message ?? "An error occurred.";
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // Logout User
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
