import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class FirestoreSchedules {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _collection = 'schedules';

  static Future<List<Map<String, dynamic>>> getEvents() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection(uid)
        .doc(_collection)
        .collection('events')
        .get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  static Future<void> addEvent(Map<String, dynamic> event) async {
    await _firestore
        .collection(uid)
        .doc(_collection)
        .collection('events')
        .add(event);
  }

  static Future<void> updateEvent(
      String eventId, Map<String, dynamic> updatedEvent) async {
    try {
      // イベントが格納されているドキュメントを検索
      final querySnapshot = await _firestore
          .collection(uid)
          .doc(_collection)
          .collection('events')
          .where('id', isEqualTo: eventId)
          .get();

      // ドキュメントが見つかった場合
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;

        // ドキュメントを更新
        await _firestore
            .collection(uid)
            .doc(_collection)
            .collection('events')
            .doc(docId)
            .update(updatedEvent);
      } else {
        print('イベントが見つかりませんでした: $eventId');
      }
    } catch (e) {
      print('イベントの更新に失敗しました: $e');
      rethrow; // エラーを再度投げる
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    try {
      // イベントが格納されているドキュメントを検索
      final querySnapshot = await _firestore
          .collection(uid)
          .doc(_collection)
          .collection('events')
          .where('id', isEqualTo: eventId)
          .get();

      // ドキュメントが見つかった場合
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;

        // ドキュメントを削除
        await _firestore
            .collection(uid)
            .doc(_collection)
            .collection('events')
            .doc(docId)
            .delete();
      } else {
        print('イベントが見つかりませんでした: $eventId');
      }
    } catch (e) {
      print('イベントの削除に失敗しました: $e');
      rethrow; // エラーを再度投げる
    }
  }

  static Future<List<Map<String, dynamic>>> getEventsForPeriod(
      DateTime start, DateTime end) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection(uid)
        .doc(_collection)
        .collection('events')
        .where('startDateTime', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('startDateTime', isLessThanOrEqualTo: end.toIso8601String())
        .get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getEventsForDay(
      DateTime day) async {
    DateTime startOfDay = DateTime(day.year, day.month, day.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    QuerySnapshot querySnapshot = await _firestore
        .collection(uid)
        .doc(_collection)
        .collection('events')
        .where('startDateTime',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('startDateTime', isLessThan: endOfDay.toIso8601String())
        .get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }
}
