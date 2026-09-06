import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 데이터베이스에 저장해둔 사용자 정보.
///
/// 파이어베이스 인증(Auth)이 주는 User와는 다르다.
/// Auth의 User는 "로그인한 사람이 누구인지"만 알려주는 것이고,
/// 그 안의 이름과 이메일은 구글이나 애플이 준 값이라 우리가 바꿀 수 없다.
///
/// 앱에서 쓰는 정보는 우리 데이터베이스에 따로 저장한다.
/// 그래야 나중에 닉네임, 소개글, 관심사처럼 로그인 수단과 상관없는 값을
/// 마음대로 덧붙일 수 있다. 지금은 강의 범위에 맞춰 이메일과 이름만 둔다.
class UserProfile {
  const UserProfile({required this.uid, this.email, this.displayName});

  /// 파이어베이스 인증이 만들어준 사용자 고유 번호.
  /// 문서 이름으로도 이 값을 그대로 쓴다.
  final String uid;

  final String? email;
  final String? displayName;

  /// 데이터베이스에서 읽어온 문서를 UserProfile로 바꾼다.
  ///
  /// 화면에서 data['email'] 처럼 직접 꺼내 쓰지 않는 이유는,
  /// 필드 이름을 바꾸거나 오타를 냈을 때 앱 곳곳이 아니라 여기 한 곳만
  /// 고치면 되게 하기 위해서다.
  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

    return UserProfile(
      uid: doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
    );
  }
}

/// 사용자 정보를 데이터베이스에 읽고 쓰는 곳.
///
/// 화면에서 FirebaseFirestore를 직접 부르지 않고 여기를 거치게 한다.
/// 컬렉션 이름('users')이나 필드 이름을 화면마다 적어두면 오타가 나기 쉽고,
/// 나중에 구조를 바꿀 때 어디를 고쳐야 하는지 찾기 어려워진다.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// 사용자 문서 하나를 가리킨다.
  ///
  /// 문서 이름(ID)으로 uid를 쓰는 게 핵심이다.
  /// 공식 문서 예제처럼 add()를 쓰면 파이어스토어가 문서 이름을 아무렇게나
  /// 지어주는데, 그러면 "지금 로그인한 사람의 문서"를 찾을 방법이 없어진다.
  /// uid를 문서 이름으로 쓰면 doc(uid) 한 줄로 바로 찾을 수 있고,
  /// 보안 규칙도 "문서 이름과 로그인한 uid가 같을 때만 허용"으로 간단해진다.
  DocumentReference<Map<String, dynamic>> _docFor(String uid) =>
      _db.collection('users').doc(uid);

  /// 로그인한 사용자 정보를 데이터베이스에 저장한다.
  ///
  /// 로그인할 때마다 부른다. 처음이면 새로 만들고, 이미 있으면 갱신한다.
  /// 둘을 나눠서 처리하지 않아도 되도록 set에 merge 옵션을 준다.
  Future<void> saveUser(User user) async {
    final DocumentReference<Map<String, dynamic>> ref = _docFor(user.uid);

    // 이미 문서가 있는지 먼저 본다. 가입일(createdAt)을 처음 한 번만
    // 기록하기 위해서다. 로그인할 때마다 덮어쓰면 가입일이 아니라
    // 마지막 로그인 날짜가 되어버린다.
    final bool isNew = !(await ref.get()).exists;

    await ref.set(<String, dynamic>{
      // 값이 있을 때만 담는다. 이게 없으면 큰 문제가 생긴다.
      //
      // 애플은 이름을 맨 처음 로그인할 때 딱 한 번만 준다.
      // 두 번째 로그인부터는 displayName이 null로 온다.
      // 그대로 저장해버리면 잘 저장돼 있던 이름이 로그인할 때마다 지워진다.
      if (user.email != null) 'email': user.email,
      if (user.displayName != null && user.displayName!.isNotEmpty)
        'displayName': user.displayName,

      // 시간은 기기 시계(DateTime.now())가 아니라 서버 시계를 쓴다.
      // 사용자 기기의 시간은 얼마든지 틀리거나 바뀔 수 있다.
      'updatedAt': FieldValue.serverTimestamp(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),

      // merge를 빼면 set은 문서를 통째로 갈아엎는다.
      // 즉 이번에 안 적은 필드는 전부 사라진다.
      // merge를 주면 적은 필드만 바꾸고 나머지는 그대로 둔다.
    }, SetOptions(merge: true));
  }

  /// 사용자 정보를 실시간으로 지켜본다.
  ///
  /// get()은 그 순간의 값을 한 번 가져오고 끝이지만,
  /// snapshots()는 값이 바뀔 때마다 계속 알려준다.
  /// 다른 기기나 콘솔에서 이름을 바꿔도 화면이 알아서 따라 바뀐다.
  Stream<UserProfile?> watchUser(String uid) {
    return _docFor(uid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> doc,
    ) {
      // 아직 저장 전이거나 방금 지운 경우엔 문서가 없다.
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    });
  }

  /// 사용자 문서를 지운다. 회원탈퇴할 때 쓴다.
  ///
  /// 파이어베이스 인증에서 계정을 지워도 데이터베이스에 남은 문서는
  /// 같이 사라지지 않는다. 완전히 다른 서비스라서 서로 모른다.
  /// 지우지 않으면 주인 없는 개인정보가 계속 남는다.
  Future<void> deleteUser(String uid) async {
    await _docFor(uid).delete();
  }
}
