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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final LoginUtil _loginUtil = LoginUtil();
  bool _isLoading = false;
  String _message = '테스트용 로그인 버튼입니다.';
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

  Future<void> _runAccountAction(
    String label,
    Future<void> Function() action,
  ) async {
    setState(() {
      _isLoading = true;
      _message = '$label 중...';
    });

    try {
      await action();
      if (!mounted) return;
      setState(() {
        // 계정 자체는 그대로라 authStateChanges가 울리지 않는다.
        // 연결 목록을 갱신하려면 여기서 직접 다시 읽어와야 한다.
        _user = FirebaseAuth.instance.currentUser;
        _message = '$label 완료';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '$label 실패: $error';
      });
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
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
              if (isSignedIn)
                ..._buildSignedInButtons()
              else
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
    final List<String> providerIds = _loginUtil.linkedProviderIds();

    return [
      Text(
        'uid: ${_user?.uid}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 4),
      // 이 계정에 어떤 로그인 수단이 묶여 있는지 보여준다.
      Text(
        '연결된 로그인: ${providerIds.join(', ')}',
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

      // 아직 안 붙은 로그인 수단만 "연동 추가" 버튼으로 보여준다.
      if (!providerIds.contains(GoogleAuthProvider.PROVIDER_ID)) ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () => _runAccountAction('구글 연동 추가', _loginUtil.linkGoogle),
            icon: const Icon(Icons.link),
            label: const Text('구글 연동 추가'),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (!providerIds.contains(AppleAuthProvider.PROVIDER_ID)) ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () => _runAccountAction('애플 연동 추가', _loginUtil.linkApple),
            icon: const Icon(Icons.link),
            label: const Text('애플 연동 추가'),
          ),
        ),
        const SizedBox(height: 12),
      ],

      // 연동 해제는 수단이 2개 이상일 때만 보여준다.
      // 마지막 하나를 떼면 로그인할 방법이 없어지기 때문이다.
      if (providerIds.length >= 2)
        ...providerIds.map(
          (String providerId) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _runAccountAction(
                          '$providerId 연동 해제',
                          () => _loginUtil.unlinkProvider(providerId),
                        ),
                icon: const Icon(Icons.link_off),
                label: Text('$providerId 연동 해제'),
              ),
            ),
          ),
        ),

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
