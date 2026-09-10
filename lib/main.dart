import 'dart:async';

import 'package:authentication_app/firebase_options.dart';
import 'package:authentication_app/screens/home_screen.dart';
import 'package:authentication_app/screens/login_screen.dart';
import 'package:authentication_app/theme/app_theme.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
 
  await FirebaseAppCheck.instance.activate(
    // 개발 중에는 debug, 출시 빌드에서는 진짜 검증 방식을 쓴다.
    //
    // 개발 빌드는 스토어를 거치지 않아서 Play Integrity나 App Attest가
    // "정식 앱"으로 인정해주지 않는다. 그래서 개발 중에 진짜 방식을 쓰면
    // 내 앱이 내 요청을 못 보내는 상황이 된다.
    //
    // debug를 쓰면 실행할 때 로그에 디버그 토큰이 찍힌다.
    // 그 값을 파이어베이스 콘솔의
    // App Check -> 앱 -> 점 세 개 -> 디버그 토큰 관리 에 등록해야
    // 개발 중에도 요청이 통과된다.
    //
    // iOS는 그냥은 안 찍힌다. Xcode에서 Runner 스킴을 열어
    // Run -> Arguments -> Arguments Passed On Launch 에
    // -FIRDebugEnabled 를 넣고 Xcode에서 한 번 실행하면 찍힌다.
    // 한 번 발급되면 그 설치본에 저장되므로, 그 뒤로는 flutter run 으로 돌려도 된다.
    // (https://firebase.google.com/docs/app-check/ios/debug-provider?hl=ko)
    //
    // 토큰은 기기마다 다르고, 앱을 지웠다 깔면 새로 발급된다.
    //
    // 공식 문서에는 androidProvider / appleProvider 로 나와 있는데,
    // 지금 버전에서는 이 이름이 deprecated 되고 providerAndroid /
    // providerApple 로 바뀌었다. 넘기는 값도 enum에서 객체로 바뀌었다.
    // 문서를 보고 따라 쳤을 때 경고가 뜨면 이 이름으로 바꿔주면 된다.
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestProvider(),

    // 웹은 reCAPTCHA 사이트 키가 따로 필요하다. 이 강의는 앱만 다루므로 비워둔다.
    // 웹까지 쓰려면 providerWeb: ReCaptchaV3Provider('사이트 키') 를 넣으면 된다.
  );

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
