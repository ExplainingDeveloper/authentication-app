import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class LoginUtil {
  /// 애플에 요청할 정보를 담은 provider.
  ///
  /// 로그인할 때도, 연동할 때도, 탈퇴 전 재인증할 때도 똑같이 쓴다.
  /// 한 곳에 모아둬야 scope를 바꿀 때 빠뜨리는 곳이 안 생긴다.
  AppleAuthProvider _appleProvider() => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  Future<UserCredential> signInWithApple() async {
    final appleProvider = _appleProvider();

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

  /// 이메일과 비밀번호로 로그인한다.
  ///
  /// 이건 강의 본편에서 다루지 않는 참고용 코드다.
  /// 앱 심사 때문에 넣어둔 것이라, 쓰실 분만 가져다 쓰시면 된다.
  ///
  /// 왜 필요한가.
  ///
  /// 애플 심사에서는 심사자가 직접 로그인해서 앱을 확인한다.
  /// 그런데 우리처럼 소셜 로그인만 있는 앱은 심사자가 들어올 방법이 없다.
  /// 아이디와 비밀번호를 적어줘도 넣을 칸이 없고, 진짜 구글 계정을 줘도
  /// 처음 보는 기기에서 로그인하면 구글이 추가 확인을 걸어서 막힌다.
  ///
  /// 그래서 심사용 계정 하나를 이메일/비밀번호로 만들어두고,
  /// 로그인 화면에 들어오는 길을 열어두는 것이다.
  ///
  /// 회원가입은 일부러 만들지 않았다.
  /// 심사용 계정은 파이어베이스 콘솔에서 직접 추가하면 되기 때문이다.
  ///   Authentication -> 사용자 탭 -> 사용자 추가
  /// (이 버튼은 로그인 방법에서 이메일/비밀번호를 켜야 나타난다)
  ///
  /// 실제 서비스에 이메일 로그인을 넣으실 거라면 여기에
  /// createUserWithEmailAndPassword 로 회원가입을,
  /// sendPasswordResetEmail 로 비밀번호 재설정을 더 붙이면 된다.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// 로그인 없이 둘러보기. (익명 로그인)
  ///
  /// 이것도 앱 심사용으로 넣어둔 참고 코드다.
  /// 애플이 말하는 "데모 모드(demonstration mode)"가 이 방식이다.
  ///
  /// 아이디도 비밀번호도 필요 없다. 파이어베이스가 이름 없는 계정을
  /// 하나 만들어주고, 그 계정으로 로그인한 상태가 된다.
  /// 심사자는 버튼 한 번만 누르면 앱 안을 볼 수 있다.
  ///
  /// 이메일 로그인(signInWithEmail)과 둘 중 하나만 있으면 된다.
  ///   이메일 로그인  실제로 서비스할 앱이라 계정 기능이 어차피 필요할 때
  ///   둘러보기      소셜 로그인만 유지하고 싶을 때
  ///
  /// 쓰시려면 파이어베이스 콘솔에서 먼저 켜야 한다.
  ///   Authentication -> 로그인 방법 -> 익명
  ///
  /// 알아두실 점.
  ///
  /// 익명 계정은 이메일도 이름도 없다. 그래서 홈 화면에 "사용자"로만 뜬다.
  /// 심사자가 기능을 둘러보는 데는 문제가 없다.
  ///
  /// 그리고 이 계정은 그 기기에만 남는다. 앱을 지우면 들어갈 방법이 없어진다.
  /// 실제 서비스에서 둘러보기를 제공하신다면, 나중에 소셜 계정으로 바꿔
  /// 이어 쓸 수 있도록 linkWithCredential 로 연결해주는 게 좋다.
  Future<UserCredential> signInAnonymously() {
    return FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  /// 지금 로그인된 계정(구글)에 애플 로그인을 추가로 붙인다.
  ///
  /// signIn이 아니라 link라는 게 핵심이다.
  /// signInWithProvider를 부르면 계정이 통째로 바뀌어버리지만,
  /// linkWithProvider는 지금 계정은 그대로 두고 로그인 수단만 하나 더 붙인다.
  ///
  /// 실패할 수 있는 대표적인 경우
  /// - provider-already-linked : 이미 붙어 있는 제공업체
  /// - credential-already-in-use : 그 애플 계정으로 이미 다른 계정이 만들어져 있음
  ///   (콘솔에서 그 계정을 지우고 다시 시도하면 된다)
  Future<UserCredential> linkApple() {
    final User? user = _requireCurrentUser();

    final appleProvider = _appleProvider();

    return _link(
      () => kIsWeb
          ? user!.linkWithPopup(appleProvider)
          : user!.linkWithProvider(appleProvider),
    );
  }

  /// 지금 로그인된 계정에 구글 로그인을 추가로 붙인다.
  ///
  /// 구글은 로그인할 때와 똑같이 네이티브로 credential만 받아온 다음,
  /// signInWithCredential이 아니라 linkWithCredential로 붙인다.
  Future<UserCredential> linkGoogle() async {
    final User? user = _requireCurrentUser();

    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _link(() => user!.linkWithCredential(credential));
  }

  /// 애플과 구글 연동이 공통으로 거치는 부분.
  ///
  /// 붙이는 방법만 다르지 실패했을 때 나오는 에러 코드는 똑같아서
  /// 여기 한 곳에서 처리한다.
  Future<UserCredential> _link(
    Future<UserCredential> Function() linkMethod,
  ) async {
    try {
      final UserCredential result = await linkMethod();

      // 연결 목록이 바뀌었으니 최신 정보를 받아온다.
      await FirebaseAuth.instance.currentUser?.reload();
      return result;
    } on FirebaseAuthException catch (error) {
      // 에러 코드는 그대로 두고 설명만 알아보기 쉽게 바꿔서 다시 던진다.
      throw FirebaseAuthException(
        code: error.code,
        message: _linkErrorMessage(error.code),
      );
    }
  }

  String _linkErrorMessage(String code) {
    switch (code) {
      case 'provider-already-linked':
        return '이미 연결되어 있는 로그인 수단입니다.';
      case 'invalid-credential':
        return '자격 증명이 유효하지 않습니다.';
      case 'credential-already-in-use':
        return '이 로그인 수단은 이미 다른 계정이 쓰고 있습니다. '
            '그 계정을 먼저 정리해야 연결할 수 있습니다.';
      default:
        // 그 외 코드는 공식 문서의 에러 목록을 참고.
        return '연동에 실패했습니다.';
    }
  }

  /// 계정은 그대로 두고 로그인 수단 하나만 떼어낸다.
  ///
  /// 회원탈퇴와 다르다. 탈퇴는 계정이 사라지지만 이건 uid가 그대로 남는다.
  /// 마지막 하나 남은 수단을 떼면 로그인할 방법이 없어지니 주의.
  Future<void> unlinkProvider(String providerId) async {
    final User? user = _requireCurrentUser();

    try {
      await user!.unlink(providerId);

      // 연결 목록이 바뀌었으니 최신 정보를 받아온다.
      await FirebaseAuth.instance.currentUser?.reload();
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthException(
        code: error.code,
        message: error.code == 'no-such-provider'
            ? '연결되어 있지 않은 로그인 수단입니다.'
            : '연동 해제에 실패했습니다.',
      );
    }
  }

  User? _requireCurrentUser() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: '로그인된 사용자가 없습니다.',
      );
    }
    return user;
  }

  /// 현재 계정에 연결된 로그인 수단 목록. (예: ['apple.com', 'google.com'])
  List<String> linkedProviderIds() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return <String>[];

    return user.providerData
        .map((UserInfo info) => info.providerId)
        .toList(growable: false);
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

    if (isAppleUser) {
      // 애플은 재인증을 반드시 거친다.
      // 삭제 때문이 아니라 revoke에 쓸 authorizationCode를 받기 위해서다.
      // 이 코드는 로그인하는 그 순간에만 발급되고 금방 만료되는 1회용이라,
      // 예전에 받아둔 걸 저장해뒀다 쓰는 방식은 안 된다.
      final appleProvider = _appleProvider();

      final UserCredential result = kIsWeb
          ? await user.reauthenticateWithPopup(appleProvider)
          : await user.reauthenticateWithProvider(appleProvider);

      // 애플 토큰 revoke.
      // 애플 문서상 토큰을 무효화하는 유일한 방법이 이 요청이다.
      // authorizationCode는 애플 플랫폼(iOS/macOS)에서 로그인했을 때만 내려온다.
      final String? authorizationCode =
          result.additionalUserInfo?.authorizationCode;

      if (authorizationCode != null) {
        await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(
          authorizationCode,
        );
      }

      await FirebaseAuth.instance.currentUser?.delete();
      return;
    }

    // 구글은 재인증이 항상 필요하지는 않다.
    //
    // 계정 삭제는 민감한 작업이라 파이어베이스가 "최근에 로그인했는지"를 보는데,
    // 방금 로그인했다면 그 조건을 이미 만족해서 바로 삭제된다.
    // 조건에 못 미칠 때만 requires-recent-login 예외가 날아온다.
    //
    // 그래서 무조건 로그인 창을 다시 띄우지 않고, 일단 삭제부터 시도한다.
    try {
      await user.delete();
      return;
    } on FirebaseAuthException catch (error) {
      if (error.code != 'requires-recent-login') rethrow;
    }

    // 여기까지 왔다면 로그인한 지 오래된 경우다. 다시 로그인시킨다.
    //
    // 이때 reauthenticateWithProvider(GoogleAuthProvider())를 쓰면 안 된다.
    // 그건 네이티브 창이 아니라 웹 OAuth 페이지를 띄우는데,
    // 안드로이드에서는 브라우저 저장소 문제로
    // "missing initial state" 에러가 나면서 실패한다.
    // 로그인할 때와 똑같이 네이티브 흐름으로 credential을 다시 받는다.
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);
    await FirebaseAuth.instance.currentUser?.delete();
  }
}
