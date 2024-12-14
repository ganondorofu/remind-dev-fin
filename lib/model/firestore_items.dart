import 'package:cloud_firestore/cloud_firestore.dart';

/// アイテムを表現するクラス。
class Item {
  String tagId;
  String name;
  bool inBag;

  Item({required this.tagId, required this.name, this.inBag = false});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inbag': inBag,
    };
  }

  static Item fromMap(String tagId, Map<String, dynamic> map) {
    return Item(
      tagId: tagId,
      name: map['name'],
      inBag: map['inbag'] ?? false,
    );
  }
}

/// Firestoreを利用してアイテムを管理するリポジトリクラス。
class ItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// `uid`に基づいてすべてのアイテムを取得するメソッド。
  Future<List<Item>> getAllItems(String uid) async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(uid).doc('items').get();
    List<Item> items = [];
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      data.forEach((tagId, itemData) {
        items.add(Item.fromMap(tagId, itemData as Map<String, dynamic>));
      });
    }
    return items;
  }

  /// 新しいアイテムを追加するメソッド。
  Future<void> addItem(String uid, Item item) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('items');
    await documentReference.set({
      item.tagId: {'name': item.name, 'inBag': item.inBag}
    }, SetOptions(merge: true));
  }

  /// `uid`と`tagId`に基づいてアイテムを削除するメソッド。
  Future<void> deleteItem(String uid, String tagId) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('items');
    await documentReference.update({tagId: FieldValue.delete()});
  }

  Future<void> toggleOrAddItem(String uid, String tagId) async {
    // 全てのアイテムを取得
    List<Item> items = await getAllItems(uid);

    // tagIdに一致するアイテムを探す
    Item? existingItem = items.firstWhere(
      (item) => item.tagId == tagId,
      orElse: () => Item(tagId: '', name: ''), // 一致するアイテムがない場合のダミーアイテム
    );

    if (existingItem.tagId.isNotEmpty) {
      // アイテムが存在する場合、inBagをトグル
      bool newInBagState = !existingItem.inBag;
      await updateItemDetails(
          uid, tagId, tagId, existingItem.name, newInBagState);
    } else {
      // アイテムが存在しない場合、新しいアイテムを追加
      Item newItem = Item(tagId: tagId, name: '名前未設定', inBag: true);
      await addItem(uid, newItem);
    }
  }

  // updateItemDetails メソッドを修正
  Future<void> updateItemDetails(String uid, String oldTagId, String newTagId,
      String name, bool inBag) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('items');
    // 新しいフィールド名で更新
    await documentReference.update({
      '$newTagId': {
        'name': name,
        'inBag': inBag,
      },
    });
    // 古いフィールドを削除（タグIDが変更された場合のみ）
    if (oldTagId != newTagId) {
      await documentReference.update({oldTagId: FieldValue.delete()});
    }
  }
}
