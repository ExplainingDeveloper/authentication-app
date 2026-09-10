import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// 다중 인증(2단계 인증)을 다루는 곳.
///
/// 로그인 수단을 하나 더 붙이는 계정 연동과는 완전히 다르다.
/// 연동은 "구글로도 애플로도 들어올 수 있게" 문을 늘리는 것이고,
/// 다중 인증은 "문을 통과한 뒤에 한 번 더 확인하는" 잠금장치다.
///
/// 그래서 비밀번호나 소셜 로그인이 뚫려도 문자를 받는 휴대폰이 없으면
/// 계정에 들어올 수 없다.
class MfaUtil {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User _requireUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: '로그인된 사용자가 없습니다.',
      );
    }
    return user;
  }

  /// 지금 계정에 등록된 2단계 인증 수단 목록.
  ///
  /// 비어 있으면 아직 아무것도 등록하지 않은 상태다.
  Future<List<MultiFactorInfo>> enrolledFactors() async {
    final User? user = _auth.currentUser;
    if (user == null) return <MultiFactorInfo>[];

    return user.multiFactor.getEnrolledFactors();
  }

  /// 휴대폰 번호를 2단계 인증 수단으로 등록한다.
  ///
  /// [askSmsCode]는 문자로 받은 6자리 코드를 사용자에게 물어보는 함수다.
  /// 이 클래스는 화면을 모르기 때문에, 코드를 어떻게 입력받을지는
  /// 화면 쪽에서 넘겨준다.
  ///
  /// 사용자가 코드 입력을 취소하면 false, 등록에 성공하면 true를 돌려준다.
  ///
  /// 파이어베이스가 콜백으로 알려주는 방식이라 Completer로 감쌌다.
  /// 그래야 화면에서 await 한 줄로 기다렸다가 결과를 쓸 수 있다.
  Future<bool> enrollPhone({
    required String phoneNumber,
    required Future<String?> Function() askSmsCode,
    String? displayName,
  }) async {
    final User user = _requireUser();

    // 지금 이 사용자가 등록을 요청했다는 걸 증명하는 표.
    // 이게 없으면 남의 계정에 내 번호를 붙이는 것도 가능해진다.
    final MultiFactorSession session = await user.multiFactor.getSession();

    final Completer<bool> completer = Completer<bool>();

    await _auth.verifyPhoneNumber(
      multiFactorSession: session,
      phoneNumber: phoneNumber,

      // 안드로이드에서 문자가 자동으로 채워질 때 불린다.
      // 등록은 아래 codeSent에서 일괄 처리하므로 여기서는 아무것도 하지 않는다.
      verificationCompleted: (PhoneAuthCredential credential) {},

      verificationFailed: (FirebaseAuthException error) {
        if (!completer.isCompleted) completer.completeError(error);
      },

      // 문자를 보낸 뒤 불린다. 여기서부터가 실제 등록 과정이다.
      codeSent: (String verificationId, int? resendToken) async {
        try {
          final String? smsCode = await askSmsCode();

          // 사용자가 입력창을 닫은 경우. 실패가 아니라 그만둔 것이다.
          if (smsCode == null || smsCode.isEmpty) {
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          final PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: smsCode,
          );

          await user.multiFactor.enroll(
            PhoneMultiFactorGenerator.getAssertion(credential),
            displayName: displayName,
          );

          if (!completer.isCompleted) completer.complete(true);
        } catch (error) {
          if (!completer.isCompleted) completer.completeError(error);
        }
      },

      // 자동 입력을 기다리다 시간이 다 됐을 때. 직접 입력하면 되므로 둔다.
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    return completer.future;
  }

  /// 등록해둔 2단계 인증 수단을 해제한다.
  Future<void> unenroll(MultiFactorInfo info) async {
    final User user = _requireUser();
    await user.multiFactor.unenroll(multiFactorInfo: info);
  }

  /// 2단계 인증이 걸린 계정의 로그인을 마무리한다.
  ///
  /// 2단계 인증을 켜두면 구글이나 애플 로그인이 성공해도 거기서 끝나지 않고
  /// FirebaseAuthMultiFactorException이 날아온다.
  /// 실패가 아니라 "1단계는 통과했으니 2단계를 마저 하라"는 신호다.
  ///
  /// 예외 안에 들어 있는 resolver에 이어서 할 정보가 다 담겨 있다.
  /// hints는 등록된 수단 목록, session은 지금 이 로그인 시도를 가리키는 표다.
  Future<bool> resolveSignIn(
    FirebaseAuthMultiFactorException exception,
    Future<String?> Function() askSmsCode,
  ) async {
    final MultiFactorResolver resolver = exception.resolver;

    // 등록된 수단이 여러 개면 고르게 해야 하지만,
    // 이 앱은 휴대폰 하나만 등록하므로 첫 번째를 쓴다.
    final MultiFactorInfo hint = resolver.hints.first;
    if (hint is! PhoneMultiFactorInfo) {
      throw FirebaseAuthException(
        code: 'unsupported-second-factor',
        message: '지원하지 않는 2단계 인증 수단입니다.',
      );
    }

    final Completer<bool> completer = Completer<bool>();

    await _auth.verifyPhoneNumber(
      // 등록할 때와 달리 번호를 직접 넘기지 않는다.
      // 이미 등록된 수단(hint)을 넘기면 파이어베이스가 그 번호로 보낸다.
      multiFactorSession: resolver.session,
      multiFactorInfo: hint,

      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (String verificationId, int? resendToken) async {
        try {
          final String? smsCode = await askSmsCode();

          if (smsCode == null || smsCode.isEmpty) {
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          final PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: smsCode,
          );

          // 여기까지 와야 비로소 로그인이 끝난다.
          await resolver.resolveSignIn(
            PhoneMultiFactorGenerator.getAssertion(credential),
          );

          if (!completer.isCompleted) completer.complete(true);
        } catch (error) {
          if (!completer.isCompleted) completer.completeError(error);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    return completer.future;
  }
}

/// 화면에 보여줄 전화번호. 등록된 번호는 뒷자리만 내려온다. (예: +82 ****1234)
String describeFactor(MultiFactorInfo info) {
  if (info is PhoneMultiFactorInfo) {
    return info.phoneNumber;
  }
  return info.displayName ?? info.factorId;
}
