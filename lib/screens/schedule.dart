import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'dart:math' show max;
import '../model/firestore_schedules.dart';
import '../model/firestore_subjects.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _selectedStartDay;
  late DateTime _selectedEndDay;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _isLoading = true;
  List<String> subjects = [];
  bool _isAddingEvent = false;
  List<Map<String, dynamic>> allEvents = [];
  DateTime lastUpdateTime = DateTime.now();
  bool _isMessageDisplayed = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay = DateTime.now();
    _selectedStartDay = _selectedDay;
    _selectedEndDay = _selectedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    subjects = await FirestoreSubjects.getSubjects();
    allEvents = await FirestoreSchedules.getEvents();
    lastUpdateTime = DateTime.now();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final rowHeight =
                                    (constraints.maxHeight - 80) / 7;
                                return TableCalendar(
                                  firstDay: DateTime.utc(2010, 1, 1),
                                  lastDay: DateTime.utc(2100, 1, 1),
                                  focusedDay: _focusedDay,
                                  onDaySelected: _onDaySelected,
                                  calendarStyle: CalendarStyle(
                                    weekendTextStyle:
                                        TextStyle(color: Colors.red),
                                    defaultTextStyle: textTheme.bodyMedium!
                                        .copyWith(color: primaryColor),
                                    tableBorder: TableBorder.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    defaultBuilder:
                                        (context, day, focusedDay) =>
                                            _buildDayContainer(
                                                day,
                                                focusedDay,
                                                rowHeight,
                                                primaryColor,
                                                textTheme),
                                    todayBuilder: (context, day, focusedDay) =>
                                        _buildDayContainer(day, focusedDay,
                                            rowHeight, primaryColor, textTheme,
                                            isToday: true),
                                    dowBuilder: (context, day) =>
                                        _buildDowBuilder(day, textTheme),
                                  ),
                                  rowHeight: rowHeight,
                                  daysOfWeekHeight: 40,
                                  headerStyle: HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: false, // Remove title centering
                                    titleTextStyle: textTheme.titleLarge!
                                        .copyWith(color: theme.brightness == Brightness.dark ? Colors.white : Colors.black), // Set title text color based on theme brightness
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      _buildEventAdder(theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _onDaySelected(selectedDay, focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedStartDay = selectedDay;
      _selectedEndDay = selectedDay;
      _isAddingEvent = true;
    });
  }

  Widget _buildDowBuilder(DateTime day, TextTheme textTheme) {
    final textColor = day.weekday == DateTime.sunday
        ? Colors.red
        : day.weekday == DateTime.saturday
            ? Colors.blue
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black;
    return Center(
      child: Text(
        DateFormat.E().format(day),
        style: textTheme.bodyMedium!.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildEventAdder(ThemeData theme) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _isAddingEvent ? 0 : -300,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            setState(() => _isAddingEvent = false);
          }
        },
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 25,
                child: Center(
                  child: Container(
                    width: 120,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        DateFormat('yyyy年MM月dd日の予定').format(_selectedDay),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      _buildEventList(),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () => _showAddEventDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8.0),
                            Text('予定を追加')
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final theme = Theme.of(context);
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('予定はありません', style: theme.textTheme.bodyMedium),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: theme.cardColor,
            child: ListTile(
              title: Text(
                event['type'] == 'task' ? event['task']! : event['event']!,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event['type'] == 'task')
                    Text('教科: ${event['subject']!}',
                        style: theme.textTheme.bodySmall),
                  if (event['type'] == 'task' &&
                      event['content'] != null &&
                      event['content'].isNotEmpty)
                    Text('内容: ${event['content']}',
                        style: theme.textTheme.bodySmall),
                  if (event['type'] == 'event')
                    Text(
                      event['isAllDay'] == true
                          ? '終日'
                          : '${event['startTime']} 〜 ${event['endTime']}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: theme.iconTheme.color),
                    onPressed: () => _showAddEventDialog(existingEvent: event),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: theme.iconTheme.color),
                    onPressed: () => _showDeleteConfirmationDialog(event),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('削除の確認'),
          content: Text('このイベントを削除してもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text('いいえ'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // ダイアログを閉じる

                // イベントを削除する
                try {
                  await FirestoreSchedules.deleteEvent(event['id']);
                  setState(() {
                    allEvents.removeWhere((e) => e['id'] == event['id']);
                  });
                } catch (e) {
                  print('削除に失敗しました: $e');
                }
              },
              child: Text('はい'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayContainer(DateTime day, DateTime focusedDay,
      double cellHeight, Color primaryColor, TextTheme textTheme,
      {bool isToday = false}) {
    final textColor = day.weekday == DateTime.sunday
        ? Colors.red
        : day.weekday == DateTime.saturday
            ? Colors.blue
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black;

    return Container(
      height: cellHeight,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          left: BorderSide(color: Colors.grey.shade300, width: 0.5),
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: EdgeInsets.all(2),
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? primaryColor : Colors.transparent,
              ),
              child: Text(
                '${day.day}',
                style: textTheme.bodyMedium!.copyWith(
                  color: isToday ? Colors.white : textColor,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: _buildEventIndicators(day, _getEventsForDay(day)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventIndicators(
      DateTime day, List<Map<String, dynamic>> events) {
    final List<Widget> indicators = [];
    const double eventHeight = 12.0;
    const double eventSpacing = 2.0;
    const double horizontalPadding = 2.0;

    var sortedEvents = [...events]
      ..sort((a, b) => _getEventDuration(b).compareTo(_getEventDuration(a)));

    Map<String, int> eventPositions = {};

    for (var i = 0; i < sortedEvents.length; i++) {
      var event = sortedEvents[i];
      final startDate = DateTime.parse(event['startDateTime']);
      final endDate = DateTime.parse(event['endDateTime']);
      final isStart = isSameDay(day, startDate);
      final isEnd = isSameDay(day, endDate);
      final isContinuation = day.isAfter(startDate) &&
          day.isBefore(endDate.add(Duration(days: 1)));

      if (isStart || isEnd || isContinuation) {
        int position;
        if (eventPositions.containsKey(event['id'])) {
          position = eventPositions[event['id']]!;
        } else {
          position = eventPositions.values.isEmpty
              ? 0
              : eventPositions.values.reduce(max) + 1;
          eventPositions[event['id']] = position;
        }

        bool showLabel = _shouldShowLabel(day, startDate, endDate);

        indicators.add(
          Positioned(
            top: position * (eventHeight + eventSpacing),
            left: isStart ? horizontalPadding : 0,
            right: isEnd ? horizontalPadding : 0,
            child: Container(
              height: eventHeight,
              decoration: BoxDecoration(
                color: Color(event['color']),
                borderRadius: BorderRadius.horizontal(
                  left: isStart ? Radius.circular(4) : Radius.zero,
                  right: isEnd ? Radius.circular(4) : Radius.zero,
                ),
              ),
              child: Center(
                child: Text(
                  showLabel ? event['event'] : '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }
    }
    return indicators;
  }

  bool _shouldShowLabel(DateTime day, DateTime startDate, DateTime endDate) {
    if (isSameDay(day, startDate)) return true;
    if (isSameDay(day, endDate)) return true;

    DateTime startOfNextWeek =
        startDate.add(Duration(days: 7 - startDate.weekday + 1));
    DateTime endOfPreviousWeek =
        endDate.subtract(Duration(days: endDate.weekday));

    if (day.isAfter(startOfNextWeek) &&
        day.isBefore(endOfPreviousWeek) &&
        day.weekday == DateTime.wednesday) {
      return true;
    }

    return false;
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Duration _getEventDuration(Map<String, dynamic> event) {
    final startDate = DateTime.parse(event['startDateTime']);
    final endDate = DateTime.parse(event['endDateTime']);
    return endDate.difference(startDate);
  }

  void _showAddEventDialog({Map<String, dynamic>? existingEvent}) {
    final _eventController = TextEditingController();
    final _contentController = TextEditingController();
    final _startDateController = TextEditingController();
    final _endDateController = TextEditingController();
    final _startDateTimeController = TextEditingController();
    final _endDateTimeController = TextEditingController();
    var selectedType = existingEvent != null ? existingEvent['type'] : 'event';
    var selectedSubject = existingEvent != null
        ? existingEvent['subject']
        : 'なし'; // デフォルトを「なし」に変更
    Color selectedColor =
        existingEvent != null ? Color(existingEvent['color']) : Colors.blue;
    var startDateTime = existingEvent != null
        ? DateTime.parse(existingEvent['startDateTime'])
        : _selectedStartDay;
    var endDateTime = existingEvent != null
        ? DateTime.parse(existingEvent['endDateTime'])
        : _selectedEndDay;
    var isAllDay = existingEvent != null ? existingEvent['isAllDay'] : false;
    var isAdding = false;

    // Initialize controllers with existing event data if editing
    if (existingEvent != null) {
      _eventController.text = existingEvent['type'] == 'task'
          ? existingEvent['task']
          : existingEvent['event'];
      _contentController.text = existingEvent['content'] ?? '';
    }

    _startDateController.text = DateFormat('yyyy-MM-dd').format(startDateTime);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(endDateTime);
    _startDateTimeController.text =
        DateFormat('yyyy-MM-dd HH:mm').format(startDateTime);
    _endDateTimeController.text =
        DateFormat('yyyy-MM-dd HH:mm').format(endDateTime);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text(existingEvent != null ? '予定を編集' : '予定を追加',
                style: theme.textTheme.titleLarge),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'event', label: Text('予定')),
                      ButtonSegment(value: 'task', label: Text('課題')),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        selectedType = newSelection.first;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  ListTile(
                    title: Text('ラベルの色', style: theme.textTheme.bodyMedium),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('色を選択'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: selectedColor,
                                onColorChanged: (Color color) {
                                  setState(() {
                                    selectedColor = color;
                                  });
                                },
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16.0),
                  if (selectedType == 'event') ...[
                    TextField(
                      controller: _eventController,
                      decoration: InputDecoration(
                        labelText: '予定名',
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      style: theme.textTheme.bodyMedium,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: Text('終日', style: theme.textTheme.bodyMedium),
                      value: isAllDay,
                      onChanged: (bool value) {
                        setState(() {
                          isAllDay = value;
                        });
                      },
                    ),
                    if (isAllDay) ...[
                      GestureDetector(
                        onTap: () async {
                          DateTimeRange? pickedDateRange =
                              await showDateRangePicker(
                            context: context,
                            initialDateRange: DateTimeRange(
                                start: startDateTime, end: endDateTime),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateRange != null) {
                            setState(() {
                              startDateTime = pickedDateRange.start;
                              endDateTime = pickedDateRange.end;
                              _startDateController.text =
                                  DateFormat('yyyy-MM-dd')
                                      .format(startDateTime);
                              _endDateController.text =
                                  DateFormat('yyyy-MM-dd').format(endDateTime);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: Column(
                            children: [
                              TextField(
                                controller: _startDateController,
                                decoration: InputDecoration(
                                  labelText: '開始日',
                                  labelStyle: theme.textTheme.bodyMedium,
                                ),
                                style: theme.textTheme.bodyMedium,
                              ),
                              TextField(
                                controller: _endDateController,
                                decoration: InputDecoration(
                                  labelText: '終了日',
                                  labelStyle: theme.textTheme.bodyMedium,
                                ),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () async {
                          final pickedDateTime = await showDatePicker(
                            context: context,
                            initialDate: startDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateTime != null) {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(startDateTime),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                startDateTime = DateTime(
                                  pickedDateTime.year,
                                  pickedDateTime.month,
                                  pickedDateTime.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                _startDateTimeController.text =
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(startDateTime);
                              });
                            }
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _startDateTimeController,
                            decoration: InputDecoration(
                              labelText: '開始日時',
                              labelStyle: theme.textTheme.bodyMedium,
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final pickedDateTime = await showDatePicker(
                            context: context,
                            initialDate: endDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateTime != null) {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endDateTime),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                endDateTime = DateTime(
                                  pickedDateTime.year,
                                  pickedDateTime.month,
                                  pickedDateTime.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                _endDateTimeController.text =
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(endDateTime);
                              });
                            }
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _endDateTimeController,
                            decoration: InputDecoration(
                              labelText: '終了日時',
                              labelStyle: theme.textTheme.bodyMedium,
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ] else if (selectedType == 'task') ...[
                    TextField(
                      controller: _eventController,
                      decoration: InputDecoration(
                        labelText: '課題名',
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      style: theme.textTheme.bodyMedium,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: InputDecoration(
                        labelText: '教科',
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      style: theme.textTheme.bodyMedium,
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value!;
                        });
                      },
                      items: ['なし', ...subjects].map((String subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: '内容',
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('キャンセル', style: theme.textTheme.labelLarge),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('保存',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
                onPressed: isAdding
                    ? null
                    : () async {
                        if (_eventController.text.isEmpty ||
                            (selectedType == 'event' &&
                                (isAllDay
                                    ? _startDateController.text.isEmpty
                                    : _startDateTimeController.text.isEmpty)) ||
                            (selectedType == 'task' &&
                                (_eventController.text.isEmpty ||
                                    selectedSubject.isEmpty ||
                                    _contentController.text.isEmpty))) {
                          _showFloatingMessage(
                              context, '入力項目を正しく入力してください', false);
                          return;
                        }
                        setState(() {
                          isAdding = true;
                        });
                        await _addOrUpdateEvent(
                          _eventController.text,
                          selectedSubject,
                          selectedType,
                          _contentController.text,
                          startDateTime,
                          endDateTime,
                          selectedColor,
                          isAllDay,
                          existingEvent?['id'],
                        );
                        Navigator.pop(context);
                        _showFloatingMessage(
                            context,
                            existingEvent != null ? '予定を更新しました' : '予定を追加しました',
                            true);
                        setState(() {
                          isAdding = false;
                        });
                        // 画面を更新するために setState を呼び出す
                        setState(() {});
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addOrUpdateEvent(
    String newEvent,
    String subject,
    String eventType,
    String content,
    DateTime startDateTime,
    DateTime endDateTime,
    Color color,
    bool isAllDay,
    String? existingEventId,
  ) async {
    if (isAllDay) {
      startDateTime =
          DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
      endDateTime =
          DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
    } else {
      startDateTime = DateTime(
        startDateTime.year,
        startDateTime.month,
        startDateTime.day,
        startDateTime.hour,
        startDateTime.minute,
      );
      endDateTime = DateTime(
        endDateTime.year,
        endDateTime.month,
        endDateTime.day,
        endDateTime.hour,
        endDateTime.minute,
      );
    }

    final event = {
      'id': existingEventId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'type': eventType,
      'event': newEvent,
      'task': eventType == 'task' ? newEvent : '',
      'subject': subject,
      'content': content,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'startTime': isAllDay ? null : DateFormat('HH:mm').format(startDateTime),
      'endTime': isAllDay ? null : DateFormat('HH:mm').format(endDateTime),
      'color': color.value,
      'isAllDay': isAllDay,
      'multiday': !isSameDay(startDateTime, endDateTime),
    };

    if (existingEventId != null) {
      await FirestoreSchedules.updateEvent(existingEventId, event);
      setState(() {
        allEvents = allEvents
            .map((e) => e['id'] == existingEventId ? event : e)
            .toList();
      });
    } else {
      await FirestoreSchedules.addEvent(event);
      setState(() {
        allEvents.add(event);
      });
    }
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

  List<Map<String, dynamic>> _getEventsForPeriod(DateTime start, DateTime end) {
    return allEvents.where((event) {
      final eventStart = DateTime.parse(event['startDateTime']);
      final eventEnd = DateTime.parse(event['endDateTime']);
      return (eventStart.isAfter(start) ||
              eventStart.isAtSameMomentAs(start)) &&
          (eventEnd.isBefore(end) || eventEnd.isAtSameMomentAs(end));
    }).toList();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return allEvents.where((event) {
      final startDate = DateTime.parse(event['startDateTime']);
      final endDate = DateTime.parse(event['endDateTime']);
      return day.isAtSameMomentAs(startDate) ||
          day.isAtSameMomentAs(endDate) ||
          (day.isAfter(startDate) &&
              day.isBefore(endDate.add(Duration(days: 1))));
    }).toList();
  }
}
