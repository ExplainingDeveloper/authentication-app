/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const appleSignin = require("apple-signin-auth");

admin.initializeApp();

// 애플이 보내는 알림의 aud 값은 유저가 "처음 로그인한 방식"에 따라 달라진다.
//   iOS 앱에서 로그인 → App ID(번들 ID)
//   웹/안드로이드에서 로그인 → Services ID
// 어느 쪽으로 들어온 유저인지 알 수 없으므로 둘 다 허용한다.
const APPLE_AUDIENCE = [
  "com.codewithsora.authentication.authenticationApp",
  "com.codewithsora.authentication.authenticationApp.service",
];

// Sign in with Apple 서버 간 알림(Server-to-Server Notifications) 엔드포인트.
// 유저가 애플 계정을 삭제하거나 우리 앱과의 연동을 끊으면 Apple이 이 URL로 알려준다.
// 배포 후 나오는 URL을 Services ID 설정의 Server-to-Server Notification Endpoint 에 등록.
exports.appleServerToServerNotification = onRequest(async (req, response) => {
  if (req.method !== "POST") {
    response.sendStatus(405);
    return;
  }

  try {
    // payload는 Apple이 서명한 JWS. 검증에 실패하면 예외가 발생하므로
    // 이 줄을 통과했다는 건 "진짜 Apple이 보낸 알림"이라는 뜻이다.
    const {events} = await appleSignin.verifyWebhookToken(req.body.payload, {
      audience: APPLE_AUDIENCE,
    });

    const {sub: appleUserId, type} = events;
    logger.info(`[Apple 알림 수신] type=${type}, sub=${appleUserId}`);

    switch (type) {
      case "email-disabled":
      case "email-enabled":
        // 이메일 릴레이(Hide My Email) 전달 설정이 켜지거나 꺼짐
        break;
      case "consent-revoked":
        // 유저가 이 앱과의 애플 계정 연동을 끊음 -> 로그아웃 처리 대상
        break;
      case "account-delete":
      case "account-deleted":
        // 애플 계정 자체가 영구 삭제됨.
        // 애플 공식 문서는 account-deleted, 일부 라이브러리/예제는 account-delete로
        // 표기가 갈린다. 놓치면 안 되는 이벤트라 둘 다 받아둔다.
        break;
      default:
        logger.warn(`알 수 없는 이벤트: ${type}`);
    }

    // TODO: [정식 출시용] appleUserId(sub)로 Firebase 유저를 찾아 실제 처리를 해야 한다.
    // Apple의 sub과 Firebase uid는 서로 다른 값이라 아래처럼 조회한다.
    //   const user = await admin.auth()
    //       .getUserByProviderUid("apple.com", appleUserId);
    // consent-revoked / account-delete 라면
    // admin.auth().deleteUser(user.uid) 로 계정 삭제.
    // (심사 가이드라인 5.1.1(v): 계정 생성을 지원하면 계정 삭제도 지원해야 함)

    response.sendStatus(200);
  } catch (error) {
    logger.error("Apple 알림 검증 실패", error);
    response.sendStatus(500);
  }
});
