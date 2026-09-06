import 'package:authentication_app/services/user_repository.dart';
import 'package:authentication_app/theme/app_theme.dart';
import 'package:authentication_app/utils/auth_feedback.dart';
import 'package:authentication_app/utils/login_util.dart';
import 'package:authentication_app/widgets/auth_button.dart';
import 'package:authentication_app/widgets/google_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// 로그인 전에 보이는 화면.
///
/// 로그인에 성공하면 여기서 화면을 직접 넘기지 않는다.
/// main.dart의 AuthGate가 로그인 상태를 지켜보고 있다가 알아서 홈으로 바꿔준다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginUtil _loginUtil = LoginUtil();
  final UserRepository _userRepository = UserRepository();

  /// 어떤 버튼을 눌러서 진행 중인지. 아무것도 안 하는 중이면 null.
  /// 로딩 표시를 누른 버튼에만 띄우려고 bool 대신 문자열로 들고 있다.
  String? _pendingProvider;

  Future<void> _signIn(
    String provider,
    Future<UserCredential> Function() signInMethod,
  ) async {
    setState(() => _pendingProvider = provider);

    try {
      final UserCredential credential = await signInMethod();

      // 로그인에 성공했으니 사용자 정보를 데이터베이스에 저장한다.
      // 처음 온 사람이면 문서가 새로 생기고, 이미 있으면 갱신된다.
      final User? user = credential.user;
      if (user != null) await _saveUserQuietly(user);

      // 성공했을 때 setState를 부르지 않는다.
      // 곧 AuthGate가 이 화면 자체를 홈으로 갈아끼우기 때문이다.
    } catch (error) {
      if (!mounted) return;

      final String? message = authErrorMessage(error);
      if (message != null) showToast(context, message);

      setState(() => _pendingProvider = null);
    }
  }

  /// 사용자 정보 저장이 실패해도 로그인은 성공한 것으로 둔다.
  ///
  /// 저장은 로그인이 끝난 뒤에 일어나는 뒷정리다.
  /// 이걸 위의 try 안에 그냥 두면, 보안 규칙이나 네트워크 문제로 저장만
  /// 실패했을 때 사용자에게 "로그인 실패"라고 잘못 알려주게 된다.
  /// 실제로는 이미 로그인된 상태라 곧 홈 화면으로 넘어가기 때문에
  /// 사용자 입장에서는 앞뒤가 맞지 않는다.
  Future<void> _saveUserQuietly(User user) async {
    try {
      await _userRepository.saveUser(user);
    } catch (_) {
      // 다음 로그인 때 다시 저장을 시도하므로 여기서는 넘어간다.
    }
  }

  @override
  Widget build(BuildContext context) {
    // 하나라도 진행 중이면 나머지 버튼도 눌리지 않게 막는다.
    final bool isBusy = _pendingProvider != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Column(
            children: <Widget>[
              // 로고와 버튼을 한 덩어리로 묶어서 화면 가운데보다 살짝 위에 둔다.
              // 위아래 빈 공간을 4:5로 나누면 눈으로 볼 때 가운데로 느껴진다.
              // (정확히 반씩 나누면 오히려 아래로 처져 보인다)
              const Spacer(flex: 4),

              const AppLogoMark(),
              const SizedBox(height: 20),
              const AppWordmark(fontSize: 32),
              const SizedBox(height: 10),
              const Text(
                '간편하게 로그인하고 시작해보세요',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),

              const SizedBox(height: 44),

              AuthButton(
                leading: const GoogleLogo(),
                label: 'Google로 계속하기',
                bordered: true,
                isLoading: _pendingProvider == 'google',
                onPressed: isBusy
                    ? null
                    : () => _signIn('google', _loginUtil.signInWithGoogle),
              ),
              const SizedBox(height: 10),
              AuthButton(
                leading: const Icon(Icons.apple, color: Colors.white, size: 22),
                label: 'Apple로 계속하기',
                background: AppColors.text,
                foreground: Colors.white,
                isLoading: _pendingProvider == 'apple',
                onPressed: isBusy
                    ? null
                    : () => _signIn('apple', _loginUtil.signInWithApple),
              ),

              const Spacer(flex: 5),

              const _TermsNotice(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 버튼 아래에 들어가는 약관 안내 문구.
class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  @override
  Widget build(BuildContext context) {
    // TODO: [정식 출시용]
    // 스토어 심사에는 이용약관과 개인정보처리방침 주소가 필요하다.
    // 여기 글자를 눌렀을 때 각 문서로 이동하도록 연결해두면 된다.

    // 줄바꿈 위치는 직접 잡아준다. 자동으로 넘기면 마지막 줄에 두 글자만
    // 남는 식으로 어색하게 잘릴 때가 있다.
    return const Text(
      '계속하면 이용약관과 개인정보처리방침에\n동의하는 것으로 간주합니다.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.5,
      ),
    );
  }
}
