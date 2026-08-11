import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class LoginUtil {
  Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    if (kIsWeb) {
      return await FirebaseAuth.instance.signInWithPopup(appleProvider);
    } else {
      return await FirebaseAuth.instance.signInWithProvider(appleProvider);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    //만약 server client id 에러가 나온다면..
    // await GoogleSignIn.instance.initialize(
    //   serverClientId:
    //       'google-services.json 에서 client_id/oauth_client (type=3) 를 가져와서 넣어주면 됨',
    // );

    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  /// 회원탈퇴.
  ///
  /// 애플 로그인 유저는 파이어베이스 계정만 지우면 안 되고,
  /// 애플 쪽 토큰까지 revoke 해줘야 한다.
  ///
  /// revoke를 안 하면 애플이 관리하는 동의 상태가 그대로 남아서,
  /// 나중에 같은 계정으로 다시 로그인해도 이름/이메일을 공유할지 물어보는
  /// 화면이 안 뜬다. (애플 기술문서 TN3194)
  Future<void> deleteAccount() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: '로그인된 사용자가 없습니다.',
      );
    }

    final bool isAppleUser = user.providerData.any(
      (UserInfo info) => info.providerId == AppleAuthProvider.PROVIDER_ID,
    );

    // 1단계. 재인증
    //
    // 계정 삭제는 민감한 작업이라 파이어베이스가 최근 로그인 상태를 요구한다.
    // 그리고 애플의 authorizationCode는 로그인하는 그 순간에만 발급되고
    // 금방 만료되는 1회용이라, 탈퇴 직전에 다시 인증받아 새로 받아와야 한다.
    final AuthProvider provider = isAppleUser
        ? (AppleAuthProvider()
            ..addScope('email')
            ..addScope('name'))
        : GoogleAuthProvider();

    final UserCredential result = kIsWeb
        ? await user.reauthenticateWithPopup(provider)
        : await user.reauthenticateWithProvider(provider);

    // 2단계. 애플 토큰 revoke
    //
    // 애플 문서상 토큰을 무효화하는 유일한 방법이 이 revoke 요청이다.
    // authorizationCode는 애플 플랫폼(iOS/macOS)에서 로그인했을 때만 내려온다.
    if (isAppleUser) {
      final String? authorizationCode =
          result.additionalUserInfo?.authorizationCode;

      if (authorizationCode != null) {
        await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(
          authorizationCode,
        );
      }
    }

    // 3단계. 파이어베이스 계정 삭제
    await FirebaseAuth.instance.currentUser?.delete();
  }
}
