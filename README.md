# authentication-app

Flutter + Firebase 로그인 강의 실습 코드입니다.
구글 로그인 → 애플 로그인 → 애플 서버 간 알림(Cloud Functions)까지 다룹니다.

## 브랜치

강의 진행 순서대로 브랜치가 나뉘어 있습니다. 필요한 시점의 코드를 받아서 쓰시면 됩니다.

| 브랜치                   | 내용                                            |
| ------------------------ | ----------------------------------------------- |
| `feature/login-prepare`  | 로그인 준비 + 구글 로그인까지                   |
| `feature/apple-login`    | 애플 로그인 + 서버 간 알림(Cloud Functions)까지 |
| `feature/account-link`   | 계정 연동 + 연동 해제 + 회원탈퇴까지            |
| `feature/ui-enhancement` | 위와 기능은 같고 화면만 다시 만든 버전 (보너스) |

`feature/ui-enhancement`는 로그인 화면·홈·설정 화면을 새로 만든 브랜치입니다.
로그인 로직(`lib/utils/login_util.dart`)은 `feature/account-link`와 완전히 같으니,
디자인이 취향에 맞지 않으면 `feature/account-link`를 그대로 쓰셔도 됩니다.
색과 앱 이름을 바꾸는 방법은 아래 [앱 이름과 색 바꾸기](#앱-이름과-색-바꾸기)에 정리해뒀습니다.

```bash
git clone <저장소 주소>
git checkout feature/apple-login
flutter pub get
```

Firebase 설정 파일(`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`)은
본인 프로젝트 것으로 교체해야 합니다.

## 앱 이름과 색 바꾸기

> `feature/ui-enhancement` 브랜치에만 해당합니다.

이 브랜치는 색과 글자 크기를 화면마다 적어두지 않고
[`lib/theme/app_theme.dart`](lib/theme/app_theme.dart) 한 파일에 모아뒀습니다.
여기만 고치면 앱 전체가 따라 바뀝니다.

### 화면에 보이는 앱 이름

파일 맨 위의 한 줄입니다. 로그인 화면의 로고 글자와 홈 화면 상단에 같이 쓰입니다.

```dart
const String kAppName = 'Aurora';
```

### 홈 화면(런처)에 보이는 앱 이름

위와는 별개입니다. 아이콘 밑에 뜨는 이름은 플랫폼마다 따로 지정합니다.

| 플랫폼 | 파일 | 항목 |
|---|---|---|
| 안드로이드 | `android/app/src/main/AndroidManifest.xml` | `android:label` |
| iOS | `ios/Runner/Info.plist` | `CFBundleDisplayName` |

### 색

`AppColors` 안의 값을 바꾸면 됩니다.

| 이름 | 기본값 | 쓰이는 곳 |
|---|---|---|
| `background` | `#FFFFFF` | 화면 배경, 상단바 |
| `text` | `#000000` | 본문 글자, 애플 로그인 버튼 배경 |
| `textSecondary` | `#737373` | 설명글, 부가 정보 |
| `separator` | `#DBDBDB` | 구분선, 구글 버튼 테두리 |
| `accent` | `#0095F6` | "연결하기" 같은 강조 글자, 연결됨 체크 |
| `danger` | `#ED4956` | 회원탈퇴 |
| `surface` | `#FAFAFA` | 배경을 살짝만 눌러줄 때 |
| `brandGradient` | 보라 → 파랑 | 로고 마크, 프로필 사진이 없을 때의 기본 이미지 |

어두운 앱으로 바꾸고 싶다면 `background`를 어두운 색으로, `text`를 밝은 색으로
서로 맞바꾸면 됩니다. 나머지 색은 그대로 둬도 대체로 어울립니다.

### 로고

`AppLogoMark`가 그라데이션 사각형에 아이콘을 얹어서 그립니다. 이미지 파일을 쓰지 않아서
따로 넣을 에셋이 없습니다. 직접 만든 로고를 쓰려면 이 위젯 안쪽을 `Image.asset(...)`으로
바꾸면 됩니다.

### 버튼 모양

`AppTheme` 안에 있습니다.

| 이름 | 기본값 | 뜻 |
|---|---|---|
| `controlHeight` | `52` | 로그인 버튼 높이 |
| `radius` | `12` | 버튼 모서리 둥글기 |
| `pagePadding` | `24` | 화면 좌우 여백 |

## 서버 간 알림 함수 배포하기

애플 로그인을 쓰는 앱은 유저가 계정 연동을 끊거나 애플 계정을 삭제했을 때
알림을 받을 서버 주소가 필요합니다. (한국 소재 개발자는 2026년 1월 1일부터 필수)

배포 방법은 두 가지입니다. **둘 중 하나만** 하시면 됩니다.

### 옵션 1. 터미널에서 배포 (권장)

Firebase CLI로 `functions/` 폴더를 그대로 배포합니다.

```bash
cd functions
npm install

cd ..
firebase login
firebase deploy --only functions
```

배포가 끝나면 나오는 주소를 애플 개발자 사이트에 등록합니다.

```
https://<리전>-<프로젝트ID>.cloudfunctions.net/appleServerToServerNotification
```

> Apple Developer → Certificates, Identifiers & Profiles → Identifiers →
> Services IDs → 해당 ID → Sign in with Apple → Configure →
> **Server-to-Server Notification Endpoint** 에 붙여넣기

### 옵션 2. Google Cloud 콘솔에서 직접 작성

옵션 1이 에러로 막히거나, 터미널 없이 해보고 싶을 때 쓰는 방법입니다.
콘솔의 **인라인 편집기**에 코드를 복사해서 붙여넣습니다.

Google Cloud 콘솔 → Cloud Run 함수 → 함수 작성 → Node.js → 인라인 편집기

붙여넣을 파일은 두 개입니다.

| 콘솔의 파일    | 복사해올 파일                                                                |
| -------------- | ---------------------------------------------------------------------------- |
| `index.js`     | [`functions/index.js`](functions/index.js)                                   |
| `package.json` | [`cloud-console/package.json`](cloud-console/package.json) ← **이걸 쓰세요** |

`package.json`을 반드시 `cloud-console/` 쪽에서 가져오세요.
`functions/package.json`을 그대로 쓰면 콘솔에서는 동작하지 않습니다. 차이는 이렇습니다.

- `@google-cloud/functions-framework` 가 들어있음 (콘솔 실행에 필요)
- `engines`, `scripts` 가 없음 (노드 버전과 배포는 콘솔 화면에서 처리)
- `type` 이 없음 (우리 코드는 CommonJS라 `"type": "module"` 이 있으면 `require` 가 깨짐)

설정할 때 주의할 점 두 가지입니다.

- **진입점(Entry point)**: `appleServerToServerNotification`
  코드의 `exports.` 뒤에 오는 함수 이름과 정확히 같아야 합니다.
- **인증**: 공개 액세스 허용
  애플이 외부에서 호출해야 하므로 인증을 걸면 요청이 차단됩니다.

배포 후 나오는 주소를 옵션 1과 똑같이 애플 개발자 사이트에 등록하면 됩니다.

## 배포가 안 될 때

강의 중 실제로 겪은 에러들과 해결법을 정리해뒀습니다.

**→ [docs/applelogin/6\_트러블슈팅\_firebaseCLI.txt](docs/applelogin/6_트러블슈팅_firebaseCLI.txt)**

자주 나오는 것들만 추리면 이렇습니다.

| 증상                                    | 원인                                                                                    |
| --------------------------------------- | --------------------------------------------------------------------------------------- |
| `/bin/sh: --: invalid option`           | Firebase CLI 독립 실행 파일의 알려진 버그 (이 저장소는 `firebase.json`에 우회책 적용됨) |
| `Runtime Node.js 18 was decommissioned` | `functions/package.json` 의 `engines` 를 `22` 로                                        |
| `Valid choices are: {"node": ...20}`    | Firebase CLI가 오래됨 → 업데이트 필요                                                   |
| `jwt audience invalid`                  | `functions/index.js` 의 `APPLE_AUDIENCE` 를 본인 번들 ID / 서비스 ID로 교체             |
| 콘솔 배포 시 `require is not defined`   | `package.json` 에 `"type": "module"` 이 남아있음                                        |

## 본인 프로젝트에 맞게 바꿔야 하는 값

[`functions/index.js`](functions/index.js) 의 `APPLE_AUDIENCE` 는 예제 값이라 반드시 교체해야 합니다.

```js
const APPLE_AUDIENCE = [
  'com.여러분의.번들ID', // iOS 앱에서 로그인한 유저
  'com.여러분의.서비스ID', // 웹에서 로그인한 유저
];
```

두 개를 다 넣는 이유는, 애플이 보내는 `aud` 값이 유저가 처음 로그인한 방식에 따라
달라지기 때문입니다. iOS 앱은 번들 ID, 웹은 서비스 ID로 옵니다.
