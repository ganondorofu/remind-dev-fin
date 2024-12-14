import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../main.dart' as main;
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const WelcomeScreen({Key? key, required this.onLoginSuccess})
      : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLogin = true;
  bool _isMainScreen = true;
  bool _isPasswordReset = false;
  bool _isMessageDisplayed = false;

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      setState(() {
        main.uid = userCredential.user?.uid ?? '';
      });
      _navigateToHome();
    } catch (e) {
      _showFloatingMessage(context, 'Googleログインエラー: $e', false);
    }
  }

  Future<void> _signInAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedAnonymousUid = prefs.getString('anonymousUid');

      if (storedAnonymousUid != null) {
        // 既存の匿名アカウントでサインイン
        await _auth.signInAnonymously();
      } else {
        // 新しい匿名アカウントを作成
        final UserCredential userCredential = await _auth.signInAnonymously();
        final String? newAnonymousUid = userCredential.user?.uid;
        if (newAnonymousUid != null) {
          await prefs.setString('anonymousUid', newAnonymousUid);
        }
      }

      setState(() {
        main.uid = _auth.currentUser?.uid ?? '';
      });
      _navigateToHome();
    } catch (e) {
      _showFloatingMessage(context, 'ゲストログインエラー: $e', false);
    }
  }

  Future<void> _signInWithEmail() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        main.uid = _auth.currentUser?.uid ?? '';
      });
      _navigateToHome();
    } catch (e) {
      _showFloatingMessage(context, 'ログインエラー: $e', false);
    }
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showFloatingMessage(context, 'パスワードが一致しません', false);
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        main.uid = _auth.currentUser?.uid ?? '';
      });
      _navigateToHome();
    } catch (e) {
      _showFloatingMessage(context, 'アカウント作成エラー: $e', false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showFloatingMessage(context, 'メールアドレスを入力してください', false);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text);
      _showFloatingMessage(context, 'パスワードリセットメールを送信しました', true);
    } catch (e) {
      _showFloatingMessage(context, 'パスワードリセットエラー: $e', false);
    }
  }

  void _navigateToHome() {
    widget.onLoginSuccess();
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

  Widget _buildMainScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'ようこそ remind dev へ',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        SignInButton(
          Buttons.email,
          text: "メールで続行",
          onPressed: () => setState(() => _isMainScreen = false),
          padding: const EdgeInsets.all(4),
        ),
        const SizedBox(height: 16),
        SignInButton(
          Buttons.google,
          text: "Googleで続行",
          onPressed: _signInWithGoogle,
          padding: const EdgeInsets.all(4),
        ),
        const SizedBox(height: 16),
        SignInButton(
          Buttons.anonymous,
          text: "ゲストモードで続行",
          onPressed: _signInAsGuest,
          padding: const EdgeInsets.all(4),
        ),
      ],
    );
  }

  Widget _buildEmailAuthScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'メールアドレス'),
        ),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'パスワード'),
          obscureText: true,
        ),
        if (!_isLogin)
          TextField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(labelText: 'パスワード（確認）'),
            obscureText: true,
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLogin ? _signInWithEmail : _signUp,
          child: Text(_isLogin ? 'ログイン' : 'アカウント作成'),
        ),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(_isLogin ? 'アカウントを作成' : 'ログイン画面に戻る'),
        ),
        if (_isLogin)
          TextButton(
            onPressed: () => setState(() => _isPasswordReset = true),
            child: const Text('パスワードをリセット'),
          ),
        TextButton(
          onPressed: () => setState(() => _isMainScreen = true),
          child: const Text('戻る'),
        ),
      ],
    );
  }

  Widget _buildPasswordResetScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'メールアドレス'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _resetPassword,
          child: const Text('パスワードリセットメールを送信'),
        ),
        TextButton(
          onPressed: () => setState(() => _isPasswordReset = false),
          child: const Text('ログイン画面に戻る'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: _isMainScreen
                ? _buildMainScreen()
                : _isPasswordReset
                    ? _buildPasswordResetScreen()
                    : _buildEmailAuthScreen(),
          ),
        ),
      ),
    );
  }
}
