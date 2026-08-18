import 'package:authentication_app/screens/settings_screen.dart';
import 'package:authentication_app/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// 로그인한 뒤에 보이는 화면.
///
/// 강의 주제는 로그인까지라서 여기 내용은 일부러 비워뒀다.
/// 실제로 앱을 만들 때는 이 자리에 각자의 화면을 넣으면 된다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openSettings() async {
    final Route<void> route = MaterialPageRoute<void>(
      builder: (_) => const SettingsScreen(),
    );
    await Navigator.of(context).push(route);

    // 설정에서 연동을 추가하거나 해제하고 돌아왔을 수 있으니 화면을 다시 그린다.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const AppWordmark(),
        actions: <Widget>[
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
          ),
          const SizedBox(width: 4),
        ],
        // 상단바와 본문을 얇은 선으로만 나눈다. 그림자를 쓰는 것보다 가볍다.
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(),
        ),
      ),
      body: ListView(
        children: <Widget>[
          const SizedBox(height: 32),
          _ProfileSection(user: user),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 60),
          const _EmptyContent(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// 프로필 사진, 이름, 이메일이 들어가는 윗부분.
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final String name = _displayName(user);

    return Column(
      children: <Widget>[
        _Avatar(photoUrl: user?.photoURL, name: name),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          // 애플 로그인에서 이메일 가리기를 선택하면 실제 주소 대신
          // privaterelay 주소가 오거나 아예 안 올 수도 있다.
          user?.email ?? '이메일 정보 없음',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),
        const _EditProfileButton(),
      ],
    );
  }

  /// 화면에 보여줄 이름을 고른다.
  ///
  /// 이름이 없을 수 있다. 애플은 첫 로그인 때만 이름을 주고,
  /// 그때 사용자가 이름 공유를 끄면 아예 안 온다.
  String _displayName(User? user) {
    final String? name = user?.displayName;
    if (name != null && name.isNotEmpty) return name;

    final String? email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;

    return '사용자';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  static const double _size = 88;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl == null
          // 사진이 없으면 이름 첫 글자를 대신 보여준다.
          // 구글은 프로필 사진 주소를 주지만 애플은 주지 않는다.
          ? Center(
              child: Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              // 사진을 못 불러와도 화면이 깨지지 않게 빈 자리로 둔다.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton();

  @override
  Widget build(BuildContext context) {
    // TODO: [정식 출시용]
    // 이름과 사진을 바꾸는 화면은 강의 범위 밖이라 눌리지 않게 두었다.
    // 만들 때는 User.updateDisplayName / updatePhotoURL 을 쓰면 된다.
    return SizedBox(
      width: 200,
      height: 36,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.separator),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          '프로필 편집',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// 아직 아무 내용도 없다는 걸 알려주는 부분.
class _EmptyContent extends StatelessWidget {
  const _EmptyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.separator, width: 1.5),
          ),
          child: const Icon(
            Icons.grid_view_outlined,
            size: 28,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '아직 콘텐츠가 없어요',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            '로그인 다음부터가 각자 만들 앱의 영역입니다.\n이 화면을 원하는 내용으로 채워보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
