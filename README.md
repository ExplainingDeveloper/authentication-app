# authentication-app

Flutter + Firebase 소셜 로그인 강의 실습 코드입니다.
구글 로그인 → 애플 로그인 → 계정 연동 → 회원탈퇴 → 출시 → Firestore까지 다룹니다.

`main`은 클래스 A와 B를 모두 합친 전체 완성본입니다.
강의를 따라오는 중이라면 아래 표에서 필요한 시점의 브랜치를 받아 쓰세요.

## 브랜치

강의 챕터별로 그 시점까지의 코드가 브랜치로 나뉘어 있습니다.
따라오다 막히면 해당 챕터 브랜치를 받아서 본인 코드와 비교해보세요.

| 챕터 | 브랜치 |
| --- | --- |
| 1. Firebase와 플러터 프로젝트 준비하기 | `feature/login-prepare` |
| 2. 구글 로그인 제대로 이해하고 구현하기 | `feature/login-prepare` |
| 3. 애플 로그인 구현하기 | `feature/apple-login` |
| 4. 여러 로그인 방법 동시에 지원하기 | `feature/account-link` |
| 4-5. (보너스) 앱 레이아웃 변경하기 | `feature/ui-enhancement` |
| 5. 유저 데이터 안전하게 보호하기 | `feature/dbconnect` |
| 6. 다중인증 (MFA) | `feature/mfa` |
| 7. App Check | `feature/appcheck` |
| 8. 마무리 | `main` (지금 이 브랜치) |

각 브랜치에는 앞 챕터 내용이 모두 들어 있습니다.
예를 들어 `feature/mfa`에는 구글·애플 로그인, 계정 연동, Firestore까지 다 들어 있고
거기에 다중 인증이 더해진 상태입니다.

```bash
git clone <저장소 주소>
git checkout feature/apple-login
flutter pub get
```

### 완성 코드

| 브랜치 | 내용 |
| --- | --- |
| `main` | 전체 완성본. 챕터 1~8이 모두 들어 있습니다. |
| `classA-final` | 계정 연동까지의 완성본 (챕터 4 끝, `feature/ui-enhancement`와 같은 코드) |

`classA-v1.0` 태그는 강의 영상과 똑같은 시점의 코드입니다.
브랜치는 오탈자 수정 등으로 조금씩 움직일 수 있으니, 영상 그대로가 필요하면 태그를 쓰세요.

### 그 외

| 브랜치 | 내용 |
| --- | --- |
| `release/google-play` | 플레이스토어 출시 준비 (서명 설정, 계정 삭제 안내 페이지) |

`feature/ui-enhancement`는 로그인 화면·홈·설정 화면을 새로 만든 브랜치입니다.
로그인 로직(`lib/utils/login_util.dart`)은 `feature/account-link`와 완전히 같으니,
디자인이 취향에 맞지 않으면 `feature/account-link`를 그대로 쓰셔도 됩니다.
색과 앱 이름을 바꾸는 방법은 아래 [앱 이름과 색 바꾸기](#앱-이름과-색-바꾸기)에 정리해뒀습니다.

## Firebase 설정 파일

Firebase 설정 파일은 각자 계정 정보라서 저장소에 올라가 있지 않습니다.
같은 위치의 `.example` 파일을 참고해서 본인 프로젝트 것으로 만들어야 합니다.

| 파일 | 위치 |
|---|---|
| `google-services.json` | `android/app/` |
| `GoogleService-Info.plist` | `ios/Runner/` |
| `firebase_options.dart` | `lib/` |

`firebase_options.dart`는 FlutterFire CLI로 만드는 게 가장 간단합니다.

```bash
flutterfire configure
```

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

## 안드로이드 릴리즈 서명

플레이스토어에 올리려면 본인 서명 키로 앱에 서명해야 합니다.
[공식 문서](https://docs.flutter.dev/deployment/android)의 순서를 그대로 따릅니다.
**세 단계를 순서대로** 해야 합니다.

### 1. 서명 키 만들기

홈 폴더에 두는 방법과, 프로젝트의 `android` 폴더 안에 두는 방법이 있습니다.
아래는 **프로젝트의 `android` 폴더 안에** 만드는 경우입니다. 프로젝트 루트에서 실행합니다.

**맥 / 리눅스 (터미널)**

```bash
keytool -genkey -v -keystore android/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**윈도우 (PowerShell)**

```powershell
keytool -genkey -v -keystore android\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

비밀번호와 이름·소속을 물어봅니다. 비밀번호는 다음 단계에서 그대로 씁니다.

`keytool: command not found`(윈도우에서는 `'keytool'은(는) ... 인식되지 않습니다`)
가 나오면 JDK 경로가 안 잡힌 것입니다.
안드로이드 스튜디오에 들어 있는 keytool 을 전체 경로로 부르면 됩니다.

**맥**

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkey -v \
  -keystore android/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**윈도우 (PowerShell)** — 경로 앞의 `&` 는 따옴표로 감싼 명령을 실행하라는 뜻입니다.

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore android\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`flutter doctor -v` 의 `Java binary at:` 줄에서 본인 컴퓨터의 JDK 위치를 확인할 수 있습니다.

### 2. android/key.properties 만들기

`android/key.properties` 파일을 새로 만들고 이렇게 채웁니다.
예시 파일이 있으니 복사해서 값만 바꿔도 됩니다.

맥 / 리눅스:

```bash
cp android/key.properties.example android/key.properties
```

윈도우 (PowerShell):

```powershell
Copy-Item android\key.properties.example android\key.properties
```

```properties
storePassword=위에서 정한 비밀번호
keyPassword=위에서 정한 비밀번호
keyAlias=upload
storeFile=/Users/본인계정/프로젝트경로/android/upload-keystore.jks
```

`~` 는 인식되지 않습니다. 전체 경로로 적거나, 상대 경로를 씁니다.
상대 경로의 기준은 `key.properties` 가 있는 `android` 폴더가 아니라
`build.gradle.kts` 가 있는 `android/app` 폴더입니다.
그래서 키스토어를 `android` 폴더에 뒀다면 한 단계 올라가야 합니다.

```properties
storeFile=../upload-keystore.jks
```

전체 경로는 컴퓨터마다 달라지니, 팀으로 작업한다면 상대 경로가 편합니다.

윈도우에서 전체 경로를 적을 때는 `\` 가 이스케이프 문자로 처리되니
`C:\\Users\\본인계정\\...` 처럼 두 번 쓰거나 `C:/Users/본인계정/...` 로 적습니다.
상대 경로(`../upload-keystore.jks`)를 쓰면 이 문제가 없습니다.

### 3. build.gradle.kts 에서 서명 설정 읽기

이 저장소에는 이미 반영돼 있습니다. `android/app/build.gradle.kts` 를 열어보면
`key.properties` 를 읽어서 `signingConfigs` 에 넣는 부분이 있습니다.

이제 빌드하면 릴리즈 키로 서명됩니다.

```bash
flutter build appbundle
```

### 자주 만나는 에러

1번·2번을 건너뛰고 3번만 하면 빌드가 이렇게 실패합니다.

```
* Where:
Build file 'android/app/build.gradle.kts' line: 42

* What went wrong:
null cannot be cast to non-null type kotlin.String
```

`key.properties` 파일이 없어서 `keystoreProperties["keyAlias"]` 가 `null` 인데
`as String` 으로 변환하려다 나는 에러입니다. **파일이 없거나, 있어도 항목 이름에
오타가 있으면** 같은 에러가 납니다. 1번·2번을 먼저 하시면 해결됩니다.

### 주의

- **키스토어 파일을 잃어버리면 앱을 업데이트할 수 없습니다.** 처음 올린 키와 다른 키로 서명하면 스토어가 거부합니다. 파일과 비밀번호를 따로 백업해두세요.
- `key.properties` 와 `.jks` 파일은 `android/.gitignore` 에 이미 들어 있어서 저장소에 올라가지 않습니다.
  키스토어를 홈 폴더가 아니라 프로젝트의 `android` 폴더 안에 뒀더라도 마찬가지입니다.
  올라가지 않는지 직접 확인하려면 이렇게 합니다.

  ```bash
  git check-ignore -v android/upload-keystore.jks android/key.properties
  ```

  두 줄 다 `android/.gitignore` 의 몇 번째 줄에서 걸렀는지 출력되면 안전합니다.
  아무것도 안 나오면 무시되지 않는다는 뜻이니 커밋하기 전에 확인하세요.

### 어떤 키로 서명됐는지 확인하기

```bash
$ANDROID_HOME/build-tools/*/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
```

`CN=Android Debug` 가 나오면 아직 디버그 키로 서명된 것입니다.

## 계정 삭제 안내 페이지

구글 플레이는 OAuth 로그인만 쓰는 앱에도 **계정 삭제 요청 URL** 을 요구합니다.
[`support/index.html`](support/index.html) 이 그 용도의 고객센터 페이지입니다.
호스팅한 뒤 플레이 콘솔의 데이터 삭제 URL 에 `.../support/#account-deletion` 을 제출하면 됩니다.

페이지 안의 `[여기에 앱 이름 입력]`, `[여기에 개발자/회사명 입력]`,
`[여기에 문의 이메일 입력]`, `[여기에 보관 기간, 예: 30일]` 네 군데는 본인 값으로 바꿔야 합니다.

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
