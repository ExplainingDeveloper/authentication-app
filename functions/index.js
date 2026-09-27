/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const appleSignin = require('apple-signin-auth');

admin.initializeApp();

// 애플이 보내는 알림의 aud 값은 유저가 "처음 로그인한 방식"에 따라 달라진다.
//   iOS 앱에서 로그인 → App ID(번들 ID)
//   웹/안드로이드에서 로그인 → Services ID
// 어느 쪽으로 들어온 유저인지 알 수 없으므로 둘 다 허용한다.
// https://developer.apple.com/account/resources/identifiers/list/bundleId
const APPLE_AUDIENCE = [
  'com.change.to.your.bundle.id', // indeitifer->appid 에서 확인
  'com.change.to.your.service.id', // indeitifer->services id로 필터바꾼뒤  확인
];

// Sign in with Apple 서버 간 알림(Server-to-Server Notifications) 엔드포인트.
// 유저가 애플 계정을 삭제하거나 우리 앱과의 연동을 끊으면 Apple이 이 URL로 알려준다.
// 배포 후 나오는 URL을 Services ID 설정의 Server-to-Server Notification Endpoint 에 등록.
exports.appleServerToServerNotification = onRequest(async (req, response) => {
  if (req.method !== 'POST') {
    response.sendStatus(405);
    return;
  }

  try {
    // payload는 Apple이 서명한 JWS. 검증에 실패하면 예외가 발생하므로
    // 이 줄을 통과했다는 건 "진짜 Apple이 보낸 알림"이라는 뜻이다.
    const { events } = await appleSignin.verifyWebhookToken(req.body.payload, {
      audience: APPLE_AUDIENCE,
    });

    const { sub: appleUserId, type } = events;
    logger.info(`[Apple 알림 수신] type=${type}, sub=${appleUserId}`);

    switch (type) {
      case 'email-disabled':
      case 'email-enabled':
        // 이메일 릴레이(Hide My Email) 전달 설정이 켜지거나 꺼짐
        break;
      case 'consent-revoked':
        // 유저가 이 앱과의 애플 계정 연동을 끊음 -> 로그아웃 처리 대상
        break;
      case 'account-delete':
      case 'account-deleted':
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
    logger.error('Apple 알림 검증 실패', error);
    response.sendStatus(500);
  }
});


// ---------------------------------------------------------------------------
// 카카오 로그인 -> Firebase 커스텀 토큰
// ---------------------------------------------------------------------------
//
// 카카오는 파이어베이스가 기본으로 지원하는 로그인 수단이 아니다.
// 구글은 GoogleAuthProvider.credential(), 애플은 AppleAuthProvider()가 있지만
// KakaoAuthProvider 같은 건 존재하지 않는다.
//
// 그래서 우리가 중간에서 보증을 선다.
//   앱   : 카카오 SDK로 로그인해서 카카오 액세스 토큰을 받는다
//   여기 : 그 토큰이 진짜인지 카카오에 물어보고, 파이어베이스 토큰을 발급한다
//   앱   : 받은 토큰으로 signInWithCustomToken()
//
// 근거 문서
//   https://firebase.google.com/docs/auth/admin/create-custom-tokens?hl=ko
//   https://developers.kakao.com/docs/latest/ko/kakaologin/rest-api

/**
 * 카카오 사용자 정보를 가져온다.
 *
 * 이 요청이 성공했다는 것 자체가 "토큰이 진짜"라는 증명이다.
 * 위조한 토큰이면 카카오가 401을 돌려주기 때문이다.
 *
 * @param {string} accessToken 앱이 카카오 SDK로 받아온 액세스 토큰
 * @return {Promise<Object>} 카카오가 내려주는 사용자 정보
 */
async function fetchKakaoUser(accessToken) {
  const response = await fetch('https://kapi.kakao.com/v2/user/me', {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok) {
    const body = await response.text();
    logger.warn(`카카오 토큰 검증 실패 (${response.status}): ${body}`);
    throw new HttpsError('unauthenticated', '카카오 토큰이 유효하지 않습니다.');
  }

  return response.json();
}

/**
 * 파이어베이스 사용자 정보를 카카오에서 받아온 값으로 맞춰둔다.
 *
 * 커스텀 토큰은 uid만 담을 수 있고 이름이나 이메일은 못 담는다.
 * 그래서 토큰을 만들기 전에 Admin SDK로 사용자 기록을 직접 손봐준다.
 * 이렇게 해두면 앱에서는 구글/애플로 로그인했을 때와 똑같이
 * user.email, user.displayName 을 쓸 수 있다.
 *
 * @param {string} uid 우리가 정한 파이어베이스 사용자 번호
 * @param {Object} profile 이메일, 이름 등 맞춰둘 값
 * @return {Promise<void>}
 */
async function upsertFirebaseUser(uid, profile) {
  try {
    await admin.auth().updateUser(uid, profile);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      await admin.auth().createUser({ uid, ...profile });
      return;
    }
    throw error;
  }
}

exports.kakaoCustomToken = onCall(async (request) => {
  const accessToken = request.data?.accessToken;

  if (!accessToken) {
    throw new HttpsError('invalid-argument', 'accessToken 이 필요합니다.');
  }

  const kakaoUser = await fetchKakaoUser(accessToken);

  // uid는 우리가 직접 정한다. 구글/애플처럼 파이어베이스가 만들어주지 않는다.
  //
  // 접두어를 붙이는 이유는 다른 로그인 수단의 uid와 겹치지 않게 하려는 것이다.
  // 한번 정하면 바꾸기 어렵다. 바꾸는 순간 기존 사용자가 전부 새 계정이 된다.
  const uid = `kakao:${kakaoUser.id}`;

  const account = kakaoUser.kakao_account ?? {};
  const profile = {};

  // 값이 있을 때만 담는다. 카카오는 동의 항목을 사용자가 끌 수 있어서
  // 이메일이나 닉네임이 아예 안 올 수 있다.
  if (account.email) profile.email = account.email;
  if (account.profile?.nickname) profile.displayName = account.profile.nickname;
  if (account.profile?.profile_image_url) {
    profile.photoURL = account.profile.profile_image_url;
  }

  await upsertFirebaseUser(uid, profile);

  const customToken = await admin.auth().createCustomToken(uid);
  logger.info(`[카카오] 커스텀 토큰 발급 uid=${uid}`);

  return { customToken };
});
