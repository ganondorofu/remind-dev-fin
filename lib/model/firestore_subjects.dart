import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class FirestoreSubjects {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _collection = 'subjects';

  static Future<List<String>> getSubjects() async {
    DocumentSnapshot docSnapshot = await _firestore.collection(uid).doc(_collection).get();
    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      return List<String>.from(data.keys);
    }
    return [];
  }

  static Future<void> addSubject(String subject) async {
    await _firestore.collection(uid).doc(_collection).set({
      subject: {}
    }, SetOptions(merge: true));
  }

  static Future<void> deleteSubject(String subject) async {
    await _firestore.collection(uid).doc(_collection).update({
      subject: FieldValue.delete()
    });
  }

  static Future<bool> subjectExists(String subject) async {
    DocumentSnapshot docSnapshot = await _firestore.collection(uid).doc(_collection).get();
    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      return data.containsKey(subject);
    }
    return false;
  }
}