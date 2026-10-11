import 'package:authentication_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 이 창에서 할 수 있는 일.
enum EmailAction {
  /// 이미 있는 계정으로 들어오기.
  signIn,

  /// 계정 새로 만들기.
  signUp,

  /// 비밀번호 재설정 메일 받기. 이때는 비밀번호 칸을 쓰지 않는다.
  resetPassword,
}

/// 이메일 로그인 창이 돌려주는 값.
///
/// 세 가지 일을 한 창에서 처리하므로 어느 쪽을 눌렀는지도 같이 돌려준다.
typedef EmailLogin = ({String email, String password, EmailAction action});

/// 이메일과 비밀번호를 받는 창.
///
/// 아래 글자를 눌러 로그인과 회원가입을 오갈 수 있다.
/// 자세한 내용은 LoginUtil 의 signInWithEmail / signUpWithEmail 설명을 보면 된다.
///
/// 사용자가 취소하면 null을 돌려준다.
Future<EmailLogin?> showEmailLoginDialog(BuildContext context) {
  return showDialog<EmailLogin>(
    context: context,
    builder: (BuildContext dialogContext) => const _EmailLoginDialog(),
  );
}

class _EmailLoginDialog extends StatefulWidget {
  const _EmailLoginDialog();

  @override
  State<_EmailLoginDialog> createState() => _EmailLoginDialogState();
}

/// 창 내용을 StatefulWidget으로 둔 이유.
///
/// TextEditingController를 함수 안에서 만들고 showDialog가 끝나자마자
/// dispose하면 안 된다. 창이 닫히는 애니메이션이 도는 동안 TextField가
/// 계속 다시 그려지는데, 그때 이미 버린 컨트롤러를 만지면서
/// "A TextEditingController was used after being disposed" 에러가 난다.
///
/// 위젯이 컨트롤러를 들고 있으면 화면에서 완전히 사라진 뒤에 dispose가
/// 불리기 때문에 이 문제가 생기지 않는다.
class _EmailLoginDialogState extends State<_EmailLoginDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  EmailAction _action = EmailAction.signIn;

  bool get _isSignUp => _action == EmailAction.signUp;
  bool get _isReset => _action == EmailAction.resetPassword;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, (
      email: _emailController.text,
      password: _passwordController.text,
      action: _action,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        switch (_action) {
          EmailAction.signIn => '이메일로 로그인',
          EmailAction.signUp => '이메일로 가입',
          EmailAction.resetPassword => '비밀번호 재설정',
        },
      ),

      // 키보드가 올라오면 창에 남는 높이가 줄어든다.
      // 스크롤을 감싸두지 않으면 그때 내용이 넘쳐서 화면이 깨진다.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              switch (_action) {
                EmailAction.signIn => '가입해둔 계정으로 들어옵니다.',
                EmailAction.signUp => '비밀번호는 6자 이상이어야 합니다.',
                EmailAction.resetPassword =>
                  '가입하신 주소로 재설정 링크를 보내드립니다.',
              },
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              // 자동 대문자와 자동 수정을 꺼둔다.
              // 켜두면 이메일 첫 글자가 대문자로 바뀌어 로그인이 실패한다.
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              decoration: const InputDecoration(hintText: '이메일'),
            ),
            // 재설정은 메일만 보내면 되므로 비밀번호를 받지 않는다.
            if (!_isReset) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '비밀번호'),
                // 키보드의 완료를 눌러도 넘어가게 한다.
                onSubmitted: (String value) => _submit(),
              ),
            ],
            const SizedBox(height: 4),

            // 세 가지 일을 한 창에서 오간다.
            // 화면을 따로 만들지 않는 쪽이 간단하다.
            Row(
              children: <Widget>[
                _ModeButton(
                  label: _action == EmailAction.signIn
                      ? '계정이 없으신가요?'
                      : '이미 계정이 있어요',
                  onPressed: () => setState(() {
                    _action = _action == EmailAction.signIn
                        ? EmailAction.signUp
                        : EmailAction.signIn;
                  }),
                ),
                if (!_isSignUp) ...<Widget>[
                  const Spacer(),
                  _ModeButton(
                    label: _isReset ? '돌아가기' : '비밀번호를 잊으셨나요?',
                    onPressed: () => setState(() {
                      _action = _isReset
                          ? EmailAction.signIn
                          : EmailAction.resetPassword;
                    }),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '취소',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            switch (_action) {
              EmailAction.signIn => '로그인',
              EmailAction.signUp => '가입하기',
              EmailAction.resetPassword => '메일 받기',
            },
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 창 아래에서 모드를 바꾸는 작은 글자 버튼.
class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.accent, fontSize: 13),
      ),
    );
  }
}
