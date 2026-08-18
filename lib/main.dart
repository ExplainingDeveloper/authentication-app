import 'dart:async';

import 'package:authentication_app/firebase_options.dart';
import 'package:authentication_app/screens/home_screen.dart';
import 'package:authentication_app/screens/login_screen.dart';
import 'package:authentication_app/theme/app_theme.dart';
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
      title: kAppName,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// 로그인 상태에 따라 보여줄 화면을 정하는 곳.
///
/// 각 화면이 직접 Navigator로 이동하지 않는다.
/// 로그인/로그아웃/탈퇴가 어디서 일어나든 결국 로그인 상태만 바뀌고,
/// 그걸 여기서 한 곳에서 지켜보다가 화면을 갈아끼운다.
/// 그래야 "로그아웃했는데 화면이 안 바뀌는" 상황이 안 생긴다.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  User? _user;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 로그인/로그아웃/탈퇴에 따라 화면이 알아서 바뀌도록 인증 상태를 구독한다.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (!mounted) return;
      setState(() {
        _user = user;
      });
    });

    _refreshUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 다른 기기에서 연동이 바뀌었을 수 있으니 앱으로 돌아올 때마다 다시 확인한다.
    if (state == AppLifecycleState.resumed) {
      _refreshUser();
    }
  }

  /// 서버에서 최신 계정 정보를 다시 받아온다.
  ///
  /// 파이어베이스는 로그인 정보를 기기에 저장해두고 앱을 켤 때 그걸 복원한다.
  /// 즉 앱을 껐다 켜도 서버에 다시 물어보지 않는다.
  /// 그래서 다른 기기에서 연동을 추가하거나 해제해도 이 기기는 모른다.
  /// reload()를 불러야 비로소 최신 상태가 반영된다.
  Future<void> _refreshUser() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } catch (_) {
      // 계정이 이미 삭제된 경우 등. 아래에서 최신 상태로 덮어쓰므로 무시한다.
    }

    if (!mounted) return;
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSignedIn = _user != null;

    return isSignedIn ? const HomeScreen() : const LoginScreen();
  }
}
