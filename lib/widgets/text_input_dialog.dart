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
}) async {
  final TextEditingController controller = TextEditingController();

  final String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: keyboardType,
              decoration: InputDecoration(hintText: hint),
              // 키보드의 완료를 눌러도 넘어가게 한다.
              onSubmitted: (String value) =>
                  Navigator.pop(dialogContext, value),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  controller.dispose();
  return result;
}
