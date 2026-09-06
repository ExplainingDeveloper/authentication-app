import 'package:authentication_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 로그인 화면에 쓰는 가로로 꽉 찬 버튼.
///
/// 구글 버튼(흰 바탕 + 테두리)과 애플 버튼(검은 바탕)이 모양만 다르고
/// 나머지는 똑같아서 하나로 묶어뒀다.
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.leading,
    required this.label,
    required this.onPressed,
    this.background = Colors.white,
    this.foreground = AppColors.text,
    this.bordered = false,
    this.isLoading = false,
  });

  /// 글자 왼쪽에 놓일 로고.
  final Widget leading;
  final String label;

  /// null이면 눌리지 않는다.
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;

  /// 흰 버튼은 배경만으로는 경계가 안 보여서 테두리를 넣는다.
  final bool bordered;

  /// 로그인 창을 띄우는 동안 로고 자리에 동그란 로딩 표시를 대신 넣는다.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    return Opacity(
      // 누를 수 없는 상태를 흐리게 해서 눈으로도 알 수 있게 한다.
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: AppTheme.controlHeight,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: bordered
                    ? Border.all(color: AppColors.separator)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: foreground,
                              ),
                            )
                          : leading,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
