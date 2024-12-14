import 'package:flutter/material.dart';
import '../model/firestore_timetables.dart';
import '../model/firestore_subjects.dart';
import 'dart:async';

class TimeTableScreen extends StatefulWidget {
  const TimeTableScreen({Key? key}) : super(key: key);

  @override
  _TimeTableScreenState createState() => _TimeTableScreenState();
}

class _TimeTableScreenState extends State<TimeTableScreen>
    with AutomaticKeepAliveClientMixin {
  late Map<String, dynamic> data = {};
  bool _saturday = true;
  bool _sunday = true;
  int times = 6;
  bool _isMessageDisplayed = false;
  bool _isLoaded = false;

  List<String> mon = List.filled(10, '');
  List<String> tue = List.filled(10, '');
  List<String> wed = List.filled(10, '');
  List<String> thu = List.filled(10, '');
  List<String> fri = List.filled(10, '');
  List<String> sat = List.filled(10, '');
  List<String> sun = List.filled(10, '');
  List<String> subjects = [''];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_isLoaded) {
      await FirestoreTimetables.initializeTimetableData();
      Map<String, dynamic> timetableData =
          await FirestoreTimetables.getTimetableData();
      List<String> subjectList = await FirestoreSubjects.getSubjects();
      setState(() {
        data = timetableData;
        times = data['times'] ?? 6;
        _saturday = data['enable_sat'] ?? true;
        _sunday = data['enable_sun'] ?? true;
        mon = List<String>.from(data['mon'] ?? List.filled(10, ''));
        tue = List<String>.from(data['tue'] ?? List.filled(10, ''));
        wed = List<String>.from(data['wed'] ?? List.filled(10, ''));
        thu = List<String>.from(data['thu'] ?? List.filled(10, ''));
        fri = List<String>.from(data['fri'] ?? List.filled(10, ''));
        sat = List<String>.from(data['sat'] ?? List.filled(10, ''));
        sun = List<String>.from(data['sun'] ?? List.filled(10, ''));
        subjects =
            subjectList.where((subject) => subject.trim().isNotEmpty).toList();
        _isLoaded = true;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _isLoaded
        ? Scaffold(
            body: Stack(
              children: [
                Center(
                  child: Table(
                    border: TableBorder.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                    defaultColumnWidth: const FlexColumnWidth(),
                    columnWidths: const {0: FixedColumnWidth(50.0)},
                    children: [
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(' '),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('月'),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('火'),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('水'),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('木'),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('金'),
                          ),
                          if (_saturday)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('土'),
                            ),
                          if (_sunday)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('日'),
                            ),
                        ],
                      ),
                      for (int i = 1; i <= times; i++)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: SizedBox(
                                height: 50,
                                child: Center(child: Text('$i')),
                              ),
                            ),
                            _buildTableCell(context, 'mon', mon, i),
                            _buildTableCell(context, 'tue', tue, i),
                            _buildTableCell(context, 'wed', wed, i),
                            _buildTableCell(context, 'thu', thu, i),
                            _buildTableCell(context, 'fri', fri, i),
                            if (_saturday)
                              _buildTableCell(context, 'sat', sat, i),
                            if (_sunday)
                              _buildTableCell(context, 'sun', sun, i),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: PopupMenuButton(
                    icon: Icon(Icons.settings),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem(
                          child: ListTile(
                            title: Text("教科の追加"),
                            trailing: Icon(Icons.add),
                            onTap: () {
                              Navigator.pop(context);
                              _showAddSubjectDialog(context);
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: StatefulBuilder(
                            builder: (BuildContext context,
                                StateSetter setStateForBuilder) {
                              return ListTile(
                                title: Text("時間数の変更"),
                                trailing: DropdownButton<int>(
                                  value: times,
                                  onChanged: (int? newValue) async {
                                    if (newValue != null) {
                                      await FirestoreTimetables.updateTimes(
                                          newValue);
                                      setState(() {
                                        times = newValue;
                                      });
                                      setStateForBuilder(() {});
                                    }
                                  },
                                  items: List.generate(
                                    10,
                                    (index) => DropdownMenuItem<int>(
                                      value: index + 1,
                                      child: Text('${index + 1}時間'),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: StatefulBuilder(
                            builder: (BuildContext context,
                                StateSetter setStateForBuilder) {
                              return Column(
                                children: [
                                  SwitchListTile(
                                    title: Text('土曜日を表示する'),
                                    value: _saturday,
                                    onChanged: (bool value) async {
                                      await FirestoreTimetables
                                          .updateSaturdayEnabled(value);
                                      setState(() {
                                        _saturday = value;
                                      });
                                      setStateForBuilder(() {});
                                    },
                                  ),
                                  SwitchListTile(
                                    title: Text('日曜日を表示する'),
                                    value: _sunday,
                                    onChanged: (bool value) async {
                                      await FirestoreTimetables
                                          .updateSundayEnabled(value);
                                      setState(() {
                                        _sunday = value;
                                      });
                                      setStateForBuilder(() {});
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              ],
            ),
          )
        : Center(child: CircularProgressIndicator());
  }

  Widget _buildTableCell(
      BuildContext context, String day, List<String> list, int i) {
    return GestureDetector(
      onTap: () {
        _showInputDialog(context, day, i - 1);
      },
      child: Container(
        height: 50,
        color: Theme.of(context).scaffoldBackgroundColor,
        alignment: Alignment.center,
        child: Text(
          list[i - 1],
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context, String day, int index) async {
    String? selectedSubject = '';
    List<String> currentDayList;
    String dayName;
    switch (day) {
      case 'mon':
        currentDayList = mon;
        dayName = '月曜日';
        break;
      case 'tue':
        currentDayList = tue;
        dayName = '火曜日';
        break;
      case 'wed':
        currentDayList = wed;
        dayName = '水曜日';
        break;
      case 'thu':
        currentDayList = thu;
        dayName = '木曜日';
        break;
      case 'fri':
        currentDayList = fri;
        dayName = '金曜日';
        break;
      case 'sat':
        currentDayList = sat;
        dayName = '土曜日';
        break;
      case 'sun':
        currentDayList = sun;
        dayName = '日曜日';
        break;
      default:
        currentDayList = [];
        dayName = '';
    }

    if (index < currentDayList.length) {
      selectedSubject = currentDayList[index];
    }

    if (!subjects.contains(selectedSubject)) {
      selectedSubject = '';
    }

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$dayNameの${index + 1}時間目の教科を選択'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedSubject,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSubject = newValue;
                      });
                    },
                    items: _buildDropdownMenuItems(),
                    isExpanded: true,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showAddSubjectDialog(context);
                    },
                    child: Text('教科を追加+'),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('キャンセル'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('保存'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedSubject);
                  },
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      await FirestoreTimetables.updateDaySubject(day, index, result);
      setState(() {
        switch (day) {
          case 'mon':
            mon[index] = result;
            break;
          case 'tue':
            tue[index] = result;
            break;
          case 'wed':
            wed[index] = result;
            break;
          case 'thu':
            thu[index] = result;
            break;
          case 'fri':
            fri[index] = result;
            break;
          case 'sat':
            sat[index] = result;
            break;
          case 'sun':
            sun[index] = result;
            break;
        }
      });
    }
  }

  List<DropdownMenuItem<String>> _buildDropdownMenuItems() {
    Set<String> uniqueSubjects = subjects.toSet();
    List<String> sortedSubjects = uniqueSubjects.toList()..sort();
    sortedSubjects.insert(0, '');

    return sortedSubjects.map((String subject) {
      return DropdownMenuItem<String>(
        value: subject,
        child: Text(
          subject.isEmpty ? '(なし)' : subject,
          style: TextStyle(fontSize: 16),
        ),
      );
    }).toList();
  }

  void _showAddSubjectDialog(BuildContext context) async {
    TextEditingController textEditingController = TextEditingController();
    bool isAdding = false;

    await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('教科を追加'),
              content: Container(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          if (subjects[index].trim().isEmpty)
                            return Container();
                          return ListTile(
                            title: Text(subjects[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await FirestoreSubjects.deleteSubject(
                                    subjects[index]);
                                String deletedSubject = subjects[index];
                                subjects.removeAt(index);
                                setDialogState(() {});
                                _showFloatingMessage(context,
                                    '教科「$deletedSubject」を削除しました', true);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    TextField(
                      controller: textEditingController,
                      decoration: const InputDecoration(
                        hintText: "教科名を入力してください",
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('キャンセル'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('追加'),
                  onPressed: isAdding
                      ? null
                      : () async {
                          String subjectName =
                              textEditingController.text.trim();
                          if (subjectName.isNotEmpty &&
                              !subjects.contains(subjectName)) {
                            setDialogState(() {
                              isAdding = true;
                            });
                            await FirestoreSubjects.addSubject(subjectName);
                            subjects.add(subjectName);
                            setDialogState(() {
                              isAdding = false;
                            });
                            textEditingController.clear();
                            _showFloatingMessage(context, '教科を追加しました', true);
                          } else {
                            _showFloatingMessage(
                                context, 'すでに同じ名前の教科が存在するか空白です。', false);
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFloatingMessage(
      BuildContext context, String message, bool isSuccess) {
    if (_isMessageDisplayed) return;

    setState(() {
      _isMessageDisplayed = true;
    });

    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 10.0,
        left: 10.0,
        right: 10.0,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                color:
                    isSuccess ? Colors.green : Color.fromARGB(255, 121, 2, 2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)!.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
      setState(() {
        _isMessageDisplayed = false;
      });
    });
  }

  void updateSaturdayEnabled(bool value) async {
    await FirestoreTimetables.updateSaturdayEnabled(value);
    setState(() {
      _saturday = value;
    });
  }

  void updateSundayEnabled(bool value) async {
    await FirestoreTimetables.updateSundayEnabled(value);
    setState(() {
      _sunday = value;
    });
  }

  bool get saturday => _saturday;
  bool get sunday => _sunday;
}
