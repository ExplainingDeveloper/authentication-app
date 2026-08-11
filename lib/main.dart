import 'dart:async';

import 'package:authentication_app/firebase_options.dart';
import 'package:authentication_app/utils/login_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GoogleSignIn.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Authentication App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final LoginUtil _loginUtil = LoginUtil();
  bool _isLoading = false;
  String _message = '테스트용 로그인 버튼입니다.';
  User? _user;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // 로그인/로그아웃/탈퇴에 따라 화면이 알아서 바뀌도록 인증 상태를 구독한다.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (!mounted) return;
      setState(() {
        _user = user;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signInWithGoogle() => _signIn(_loginUtil.signInWithGoogle);

  Future<void> _signInWithApple() => _signIn(_loginUtil.signInWithApple);

  Future<void> _signIn(Future<UserCredential> Function() signInMethod) async {
    setState(() {
      _isLoading = true;
      _message = '로그인 시도 중...';
    });

    try {
      final result = await signInMethod();
      if (!mounted) return;
      setState(() {
        _message = '로그인 성공: ${result.user?.uid}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '로그인 실패: $error';
      });
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await _loginUtil.signOut();
    if (!mounted) return;
    setState(() {
      _message = '로그아웃 했습니다.';
    });
  }

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('회원탈퇴'),
          content: const Text(
            '계정을 삭제합니다.\n'
            '확인을 누르면 본인 확인을 위해 다시 로그인 창이 뜹니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('탈퇴하기'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _message = '회원탈퇴 처리 중...';
    });

    try {
      await _loginUtil.deleteAccount();
      if (!mounted) return;
      setState(() {
        _message = '회원탈퇴가 완료됐습니다.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '회원탈퇴 실패: $error';
      });
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSignedIn = _user != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Login Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (isSignedIn) ..._buildSignedInButtons() else
                ..._buildSignInButtons(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSignInButtons() {
    return [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login),
          label: Text(_isLoading ? '로그인 중...' : '구글 로그인'),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _signInWithApple,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.apple),
          label: Text(_isLoading ? '로그인 중...' : '애플 로그인'),
        ),
      ),
    ];
  }

  List<Widget> _buildSignedInButtons() {
    return [
      Text(
        'uid: ${_user?.uid}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isLoading ? null : _signOut,
          child: const Text('로그아웃'),
        ),
      ),
      const SizedBox(height: 12),
      // 실제 앱에서는 보통 설정 화면 안에 넣는 기능이다.
      // 애플은 계정을 만들 수 있는 앱이면 지울 수도 있어야 한다고 요구한다.
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _deleteAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
          child: Text(_isLoading ? '처리 중...' : '회원탈퇴'),
        ),
      ),
    ];
  }
}
