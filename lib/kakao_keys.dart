/// 카카오 로그인에 필요한 값들.
///
/// 이 파일은 저장소에 올라가지 않습니다. (.gitignore)
/// 같은 폴더의 kakao_keys.dart.example 을 참고해서 본인 값으로 만드세요.
library;

/// 네이티브 앱 키. 안드로이드와 iOS에서 씁니다.
const String kakaoNativeAppKey = 'eae93fe6f9a42c1ed889fffddb93b947';

/// JavaScript 앱 키. 웹에서 씁니다.
const String kakaoJavaScriptAppKey = '2b6b53ef84cbeaf086c40017b1b4d38d';

/// 카카오 토큰을 파이어베이스 토큰으로 바꿔주는 함수의 주소.
///
/// 클라우드 콘솔에서 직접 만든 함수라 run.app 주소를 쓴다.
const String kakaoFunctionUrl =
    'https://kakaologin-549760059710.europe-west1.run.app';
