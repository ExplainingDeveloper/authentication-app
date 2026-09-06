import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 에러를 화면에 보여줄 문장으로 바꾼다.
///
/// 예외 객체를 그대로 찍으면 `FirebaseAuthException([firebase_auth/...])` 같은
/// 개발자용 문자열이 사용자에게 그대로 노출된다.
///
/// 사용자가 로그인 창을 그냥 닫은 경우에는 null을 돌려준다.
/// 이건 실패가 아니라 사용자가 그만둔 것이라, 아무 메시지도 안 띄우는 게 맞다.
String? authErrorMessage(Object error) {
  // 구글은 취소를 전용 예외로 알려준다.
  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) return null;
    return '구글 로그인에 실패했습니다.';
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      // 애플 로그인 창을 닫았을 때 올라오는 코드들.
      case 'canceled':
      case 'user-canceled':
      case 'web-context-canceled':
        return null;
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인한 뒤 시도해주세요.';
    }

    // LoginUtil에서 이미 사람이 읽을 문장으로 바꿔 던진 경우가 있다.
    // 그런 메시지는 그대로 살려서 보여준다.
    final String? message = error.message;
    if (message != null && message.isNotEmpty && !message.contains('[')) {
      return message;
    }

    return '문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }

  return '문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
}

/// 화면 아래에 잠깐 떴다 사라지는 안내 메시지.
void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
