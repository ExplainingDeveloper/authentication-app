import 'package:authentication_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 한 줄 입력을 받는 창.
///
/// 2단계 인증에서 전화번호와 인증번호를 받을 때 쓴다.
/// 설정 화면과 로그인 화면 두 곳에서 똑같은 창이 필요해서 따로 뺐다.
///
/// 사용자가 취소하면 null을 돌려준다.
Future<String?> showTextInputDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String hint,
  required String actionLabel,
  TextInputType keyboardType = TextInputType.text,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => _TextInputDialog(
      title: title,
      message: message,
      hint: hint,
      actionLabel: actionLabel,
      keyboardType: keyboardType,
    ),
  );
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
class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.message,
    required this.hint,
    required this.actionLabel,
    required this.keyboardType,
  });

  final String title;
  final String message;
  final String hint;
  final String actionLabel;
  final TextInputType keyboardType;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),

      // 키보드가 올라오면 창에 남는 높이가 줄어든다.
      // 스크롤을 감싸두지 않으면 그때 내용이 넘쳐서 화면이 깨진다.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: widget.keyboardType,
              decoration: InputDecoration(hintText: widget.hint),
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
          child: Text(
            widget.actionLabel,
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
