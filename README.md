# authentication-app

Flutter + Firebase 로그인 강의 실습 코드입니다.
구글 로그인 → 애플 로그인 → 계정 연동 → 회원탈퇴까지 다룹니다.

## 브랜치

강의 진행 순서대로 브랜치가 나뉘어 있습니다.
필요한 시점의 코드를 받아서 쓰시면 됩니다.

| 브랜치 | 내용 |
|---|---|
| `feature/login-prepare` | 로그인 준비 + 구글 로그인까지 |
| `feature/apple-login` | 애플 로그인 + 서버 간 알림(Cloud Functions)까지 |
| `feature/account-link` | 계정 연동 + 연동 해제 + 회원탈퇴까지 |
| `feature/ui-enhancement` | 위와 기능은 같고 화면만 다시 만든 버전 (보너스) |

```bash
git clone <저장소 주소>
git checkout feature/apple-login
flutter pub get
```

각 브랜치의 README에 그 시점에 필요한 설정 안내가 들어 있습니다.
애플 로그인부터는 서버 간 알림 함수 배포 방법도 함께 적혀 있습니다.

> `main`은 `feature/login-prepare`와 같은 코드입니다. 구글 로그인까지만 들어 있습니다.

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
