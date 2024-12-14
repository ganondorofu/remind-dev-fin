import 'package:firebase_auth/firebase_auth.dart';

/// ユーザーを表現するクラス。
class UserModel {
  final String uid;
  final String email;

  UserModel({required this.uid, required this.email});

  /// Firebase UserからUserModelを生成するファクトリメソッド。
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email!,
    );
  }
}

/// Firebase Authenticationを利用してユーザーを管理するリポジトリクラス。
class UserRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// 新しいユーザーを登録するメソッド。
  Future<UserModel?> addUser(String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return UserModel.fromFirebaseUser(userCredential.user!);
    } catch (e) {
      print('Error adding user: $e');
      return null;
    }
  }

  /// 現在のユーザー情報を取得するメソッド。
  UserModel? getUser() {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      return UserModel.fromFirebaseUser(user);
    }
    return null;
  }

  /// ユーザーを削除するメソッド。
  Future<void> deleteUser() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      print('Error deleting user: $e');
    }
  }
}
