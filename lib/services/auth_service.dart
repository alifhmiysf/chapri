import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';


class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;


  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String username,
    required String chapriId,
  }) async {

    try {

      UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );


      final firebaseUser = credential.user!;


      UserModel user = UserModel(
        uid: firebaseUser.uid,
        name: name,
        username: username,
        chapriId: chapriId,
        email: email,
      );


      await _firestore
          .collection("users")
          .doc(firebaseUser.uid)
          .set(
            user.toMap(),
          );


      return user;


    } catch(e){

      throw Exception(
        e.toString(),
      );

    }

  }



  Future<User?> login({
    required String email,
    required String password,
  }) async {

    UserCredential credential =
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );


    return credential.user;

  }



  Future<void> logout() async {

    await _auth.signOut();

  }



  User? get currentUser =>
      _auth.currentUser;

}