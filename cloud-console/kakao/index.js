/**
 * 카카오 로그인 -> Firebase 커스텀 토큰
 *
 * Google Cloud 콘솔의 인라인 편집기에 그대로 붙여넣는 파일입니다.
 * 터미널로 배포하실 거면 functions/index.js 를 쓰시면 됩니다.
 *
 * 콘솔 설정
 *   진입점(Entry point) : kakaoCustomToken
 *   런타임              : Node.js 22
 *   인증                : 공개 액세스 허용
 *
 * 인증을 공개로 열어두는 게 불안해 보이실 텐데요.
 * 호출한 사람이 누구인지는 파이어베이스 SDK가 따로 확인합니다.
 * 여기를 잠가버리면 앱에서 보내는 요청 자체가 막혀서 로그인이 안 됩니다.
 *
 * 왜 이 함수가 필요한가
 *
 * 카카오는 파이어베이스가 기본으로 지원하는 로그인 수단이 아닙니다.
 * 구글은 GoogleAuthProvider, 애플은 AppleAuthProvider 가 있지만
 * KakaoAuthProvider 같은 건 없습니다.
 *
 * 그래서 우리가 중간에서 보증을 섭니다.
 *   앱   카카오 SDK로 로그인해서 카카오 액세스 토큰을 받는다
 *   여기 그 토큰이 진짜인지 카카오에 물어보고, 파이어베이스 토큰을 발급한다
 *   앱   받은 토큰으로 signInWithCustomToken()
 *
 * 근거 문서
 *   https://firebase.google.com/docs/auth/admin/create-custom-tokens?hl=ko
 *   https://developers.kakao.com/docs/latest/ko/kakaologin/rest-api
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * 카카오 사용자 정보를 가져옵니다.
 *
 * 이 요청이 성공했다는 것 자체가 "토큰이 진짜"라는 증명입니다.
 * 위조한 토큰이면 카카오가 401을 돌려주기 때문입니다.
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
 * 파이어베이스 사용자 정보를 카카오에서 받아온 값으로 맞춰둡니다.
 *
 * 커스텀 토큰은 uid만 담을 수 있고 이름이나 이메일은 못 담습니다.
 * 그래서 토큰을 만들기 전에 Admin SDK로 사용자 기록을 직접 손봐줍니다.
 * 이렇게 해두면 앱에서는 구글이나 애플로 로그인했을 때와 똑같이
 * user.email, user.displayName 을 쓸 수 있습니다.
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

  // uid는 우리가 직접 정합니다. 구글이나 애플처럼 파이어베이스가 만들어주지 않습니다.
  //
  // 접두어를 붙이는 이유는 다른 로그인 수단의 uid와 겹치지 않게 하려는 것입니다.
  // 한번 정하면 바꾸기 어렵습니다. 바꾸는 순간 기존 사용자가 전부 새 계정이 됩니다.
  const uid = `kakao:${kakaoUser.id}`;

  const account = kakaoUser.kakao_account ?? {};
  const profile = {};

  // 값이 있을 때만 담습니다. 카카오는 동의 항목을 사용자가 끌 수 있어서
  // 이메일이나 닉네임이 아예 안 올 수 있습니다.
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
