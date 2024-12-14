import 'dart:async';

import 'package:flutter/material.dart';
import '../model/firestore_items.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../main.dart' as main;

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});
  @override
  _ItemsScreenState createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Item> _filteredItems = [];
  Map<Item, Set<int>> itemSelections = {};
  List<ScanResult> scanResults = [];
  bool isConnected = false;
  final List<Item> _items = []; // 全アイテムのリスト
  final ItemRepository _itemRepository = ItemRepository(); // アイテムリポジトリのインスタンス
  final uid = main.uid; // UIDを適切に設定
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;

  @override
  void dispose() {
    _searchController.removeListener(_filterItems);
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        return item.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    startScan();
    _searchController.addListener(_filterItems);
    _filteredItems = List.from(_items); // 初期状態では全アイテムを表示
    _getItems(); // アイテムを取得するメソッドを呼び出す
  }

  void _addItem(String tagId) {
    if (mounted) {
      setState(() {
        _filteredItems.add(Item(name: '名前未設定', tagId: tagId, inBag: false));
      });
    }
  }

  void _onSelectionChanged(Item item, Set<int> set, String newTagId) {
    if (mounted) {
      setState(() {
        item.inBag = set.contains(1);
      });
      _itemRepository.updateItemDetails(
        uid, // UID
        item.tagId, // 既存のtagId
        newTagId, // 新しいtagId（変更がない場合）
        item.name,
        item.inBag,
      );
      item.tagId = newTagId;
    }
  }

  Future<void> _getItems() async {
    List<Item> items = (await _itemRepository.getAllItems(uid)).cast<Item>();
    if (mounted) {
      setState(() {
        _items.addAll(items);
        _filteredItems = List.from(_items);
      });
    }
    print(items);
  }

  void startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
        isConnected = true;
        Navigator.of(context).pop();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );
      discoverServices(device);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  Future<void> _checkAndUpdateItem(String tagId) async {
    List<Item> items = await _itemRepository.getAllItems(uid);
    Item? existingItem = items.firstWhere(
      (item) => item.tagId == tagId,
      orElse: () => Item(tagId: '', name: ''), // 一致するアイテムがない場合のダミーアイテム
    );

    if (existingItem.tagId.isNotEmpty) {
      // アイテムが存在する場合、inBagをtrueに更新
      await _itemRepository.updateItemDetails(
          uid, tagId, tagId, existingItem.name, true);
    } else {
      // アイテムが存在しない場合、新しいアイテムを追加
      Item newItem = Item(name: '名前未設定', tagId: tagId, inBag: true);
      await _itemRepository.addItem(uid, newItem);
      setState(() {
        _filteredItems.add(newItem);
      });
    }
  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      print('Discovered service: ${service.uuid}');
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        print('Discovered characteristic: ${characteristic.uuid}');
        if (characteristic.uuid.toString() ==
            "c6f6bb69-2b85-47fb-993b-584440b6a785") {
          setState(() {
            targetCharacteristic = characteristic;
          });
          if (characteristic.properties.notify) {
            try {
              await characteristic.setNotifyValue(true);
              final subscription =
                  characteristic.onValueReceived.listen((value) {
                String _value = String.fromCharCodes(value);
                _checkAndUpdateItem(_value);
                print('Received data: $_value');
              });
              device.cancelWhenDisconnected(subscription);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notify enabled for characteristic')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to set notify: $e')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Characteristic does not support notify')),
            );
          }
          break;
        }
      }
    }
  }

  void _showBluetoothPopup() async {
    bool isBluetoothOn = await FlutterBluePlus.isOn;
    if (!isBluetoothOn) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bluetoothがオフです'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth_disabled,
                  size: 100,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text('Bluetoothをオンにしてください...'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      );
    } else {
      startScan();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('リーダーと接続'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final result = scanResults[index];
                  return ListTile(
                    title: Text(result.device.name.isEmpty
                        ? '不明なデバイス'
                        : result.device.name),
                    subtitle: Text(result.device.id.toString()),
                    trailing: ElevatedButton(
                      onPressed: () => connectToDevice(result.device),
                      child: const Text('接続'),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showDeleteDialog(Item item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: Text('$item を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                await _itemRepository.deleteItem(uid, item.tagId);
                setState(() {
                  _filteredItems.remove(item);
                  _items.remove(item);
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 8.0),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '検索',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.bluetooth,
                color: isConnected ? Colors.green : Colors.grey,
              ),
              onPressed: _showBluetoothPopup,
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index]; // ここで item を定義
          return ListTile(
            title: Text(item.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<int> set) =>
                      _onSelectionChanged(item, set, item.tagId),
                  segments: [
                    ButtonSegment(
                        value: 1,
                        label: Icon(Icons.backpack, color: Colors.grey[700])),
                    ButtonSegment(
                        value: 0,
                        label:
                            Icon(Icons.no_backpack, color: Colors.grey[700])),
                  ],
                  selected: item.inBag ? {1} : {0},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        TextEditingController nameController =
                            TextEditingController(text: item.name);
                        TextEditingController tagIdController =
                            TextEditingController(text: item.tagId);

                        return AlertDialog(
                          title: const Text('編集'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: nameController,
                              ),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('アイテム名'),
                              ),
                              TextField(
                                controller: tagIdController,
                              ),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('タグID'),
                              ),
                              SizedBox(
                                width: 200,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showDeleteDialog(item);
                                  },
                                  child: const Text(
                                    '削除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              )
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('キャンセル'),
                            ),
                            TextButton(
                              onPressed: () async {
                                // Firestoreの値を更新
                                await _itemRepository.updateItemDetails(
                                  uid, // UID
                                  _filteredItems[index].tagId, // 既存のtagId
                                  tagIdController.text, // 新しいtagId
                                  nameController.text,
                                  _filteredItems[index].inBag,
                                );
                                Navigator.of(context).pop();
                                setState(() {
                                  _filteredItems[index] = Item(
                                    tagId: tagIdController.text,
                                    name: nameController.text,
                                    inBag: _filteredItems[index].inBag,
                                  );
                                });
                              },
                              child: const Text('保存'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              // アイテムがタップされたときの処理
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$item tapped')),
              );
            },
          );
        },
      ),
    );
  }
}
