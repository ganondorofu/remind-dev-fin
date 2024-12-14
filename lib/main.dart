import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home.dart';
import 'screens/schedule.dart' as schedule;
import 'screens/timetable.dart';
import 'screens/item.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome.dart';
import 'package:firebase_auth/firebase_auth.dart';

String uid = '';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  String? themeModeString = prefs.getString('themeMode');
  ThemeMode themeMode;
  if (themeModeString == 'ThemeMode.light') {
    themeMode = ThemeMode.light;
  } else if (themeModeString == 'ThemeMode.dark') {
    themeMode = ThemeMode.dark;
  } else {
    themeMode = ThemeMode.system;
  }
  runApp(MyApp(initialThemeMode: themeMode));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MyApp({Key? key, required this.initialThemeMode}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  // 追加：現在のテーマモードを取得するゲッター
  ThemeMode get currentThemeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _changeThemeMode(ThemeMode newThemeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = newThemeMode;
    });
    await prefs.setString('themeMode', newThemeMode.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タイトル',
      theme: ThemeData(
        fontFamily: 'NotoSansJP',
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.light(
          primary: Color.fromARGB(255, 2, 138, 32),
          secondary: Color.fromARGB(255, 2, 138, 32),
          background: Colors.white,
          surface: Colors.white,
          onBackground: Colors.black,
          onSurface: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: 'NotoSansJP',
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.dark(
          primary: Color.fromARGB(255, 2, 138, 32),
          secondary: Color.fromARGB(255, 2, 138, 32),
          background: Colors.grey[900]!,
          surface: Colors.grey[800]!,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: MyStatefulWidget(
        onThemeModeChanged: _changeThemeMode,
        currentThemeMode: _themeMode, // 追加：現在のテーマモードを渡す
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;
  final ThemeMode currentThemeMode; // 追加：現在のテーマモードを受け取る

  const MyStatefulWidget({
    Key? key,
    required this.onThemeModeChanged,
    required this.currentThemeMode, // 追加
  }) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  static final List<Widget> _screens = [
    const HomeScreen(),
    const TimeTableScreen(),
    const schedule.ScheduleScreen(),
    const ItemsScreen(),
  ];

  int _selectedIndex = 0;
  bool _isMessageDisplayed = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  Future<void> _signOut() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('確認'),
          content: Text('本当にサインアウトしますか？'),
          actions: <Widget>[
            TextButton(
              child: Text('いいえ'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('はい'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        setState(() {});
        _showFloatingMessage(context, 'サインアウトしました', true);
      } catch (e) {
        _showFloatingMessage(context, 'サインアウトエラー: $e', false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          return _buildMainScaffold();
        } else {
          return WelcomeScreen(onLoginSuccess: () {
            setState(() {});
          });
        }
      },
    );
  }

  Scaffold _buildMainScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
      ),
      drawer: _buildCommonDrawer(context),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.table_view), label: '時間割'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'スケジュール'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: '持ち物'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'ホーム';
      case 1:
        return '時間割';
      case 2:
        return 'スケジュール';
      case 3:
        return '持ち物';
      default:
        return '';
    }
  }

  Widget _buildCommonDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'メニュー',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('テーマ', style: TextStyle(fontSize: 16)),
                DropdownButton<ThemeMode>(
                  value: widget.currentThemeMode, // 修正：widget.currentThemeModeを使用
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      widget.onThemeModeChanged(newValue);
                      // 追加：状態を更新してUIを再構築
                      setState(() {});
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('システムテーマ'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('ライトテーマ'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('ダークテーマ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('サインアウト'),
            onTap: () async {
              await _signOut();
              Navigator.pop(context); // Close the drawer
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('ユーザーUID: $uid'),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ライセンス情報'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              _showLicenses(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LicensePage()),
    );
  }
}