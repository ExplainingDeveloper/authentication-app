import 'package:authentication_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 이메일 로그인 창이 돌려주는 값.
///
/// 이메일과 비밀번호를 한 번에 받아야 해서 둘을 묶었다.
typedef EmailLogin = ({String email, String password});

/// 이메일과 비밀번호를 받는 창.
///
/// 앱 심사용으로 넣어둔 참고 코드다. 자세한 내용은
/// LoginUtil.signInWithEmail 의 설명을 보면 된다.
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이메일로 로그인'),

      // 키보드가 올라오면 창에 남는 높이가 줄어든다.
      // 스크롤을 감싸두지 않으면 그때 내용이 넘쳐서 화면이 깨진다.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '미리 만들어둔 계정으로 들어옵니다.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: '비밀번호'),
              // 키보드의 완료를 눌러도 넘어가게 한다.
              onSubmitted: (String value) => _submit(),
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
          child: const Text(
            '로그인',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
