import 'package:authentication_app/theme/app_theme.dart';
import 'package:authentication_app/utils/auth_feedback.dart';
import 'package:authentication_app/utils/login_util.dart';
import 'package:authentication_app/widgets/google_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// 앱 버전.
///
/// TODO: [정식 출시용]
/// 지금은 손으로 적어뒀다. pubspec.yaml의 version과 따로 놀지 않게 하려면
/// package_info_plus 패키지로 앱에서 직접 읽어오는 방법을 쓰면 된다.
const String kAppVersion = '1.0.0';

/// 설정 화면.
///
/// 로그인 수단 연동/해제, 로그아웃, 회원탈퇴가 모두 여기에 모여 있다.
/// 실제 앱들도 이 기능들을 설정 화면 안에 넣는다.
/// 특히 회원탈퇴는 애플이 "계정을 만들 수 있으면 지울 수도 있어야 한다"고
/// 요구하기 때문에, 사용자가 찾을 수 있는 곳에 반드시 있어야 한다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LoginUtil _loginUtil = LoginUtil();
  bool _isLoading = false;

  /// 연동 추가와 연동 해제가 공통으로 거치는 부분.
  ///
  /// 진행 중 표시를 켜고, 끝나면 화면을 새로 그리고, 실패하면 안내를 띄운다.
  /// 이 흐름은 어느 쪽이든 똑같아서 한 곳에 모아뒀다.
  Future<void> _run(
    String successMessage,
    Future<void> Function() action,
  ) async {
    setState(() => _isLoading = true);

    try {
      await action();
      if (!mounted) return;
      showToast(context, successMessage);
    } catch (error) {
      if (!mounted) return;
      final String? message = authErrorMessage(error);
      if (message != null) showToast(context, message);
    }

    // 연동은 계정 자체가 바뀌는 게 아니라서 로그인 상태 감시가 반응하지 않는다.
    // 연결 목록을 새로 보여주려면 여기서 직접 화면을 다시 그려야 한다.
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _onProviderTap(_ProviderKind kind, bool isLinked) async {
    final List<String> linked = _loginUtil.linkedProviderIds();

    if (!isLinked) {
      await _run(
        '${kind.label} 계정을 연결했습니다.',
        kind == _ProviderKind.google
            ? _loginUtil.linkGoogle
            : _loginUtil.linkApple,
      );
      return;
    }

    // 마지막 하나 남은 수단까지 떼면 로그인할 방법이 없어진다. 그래서 막는다.
    if (linked.length < 2) {
      showToast(context, '로그인 수단이 하나뿐이라 해제할 수 없습니다.');
      return;
    }

    final bool confirmed = await _confirm(
      title: '${kind.label} 연결 해제',
      message: '${kind.label} 계정으로는 더 이상 로그인할 수 없게 됩니다.\n계정과 데이터는 그대로 남습니다.',
      actionLabel: '연결 해제',
    );
    if (!confirmed) return;

    await _run(
      '${kind.label} 연결을 해제했습니다.',
      () => _loginUtil.unlinkProvider(kind.providerId),
    );
  }

  Future<void> _signOut() async {
    final bool confirmed = await _confirm(
      title: '로그아웃',
      message: '로그아웃해도 계정은 그대로 남아 있어서 언제든 다시 로그인할 수 있습니다.',
      actionLabel: '로그아웃',
    );
    if (!confirmed) return;

    await _loginUtil.signOut();

    // 로그아웃하면 AuthGate가 로그인 화면으로 바꿔주지만,
    // 그건 맨 아래 화면을 갈아끼우는 것이라 위에 쌓인 이 설정 화면은 그대로 남는다.
    // 그래서 여기서 직접 닫아줘야 한다.
    if (mounted) Navigator.of(context).popUntil((Route<void> r) => r.isFirst);
  }

  Future<void> _deleteAccount() async {
    final bool confirmed = await _confirm(
      title: '회원탈퇴',
      message:
          '계정과 관련된 정보가 모두 삭제되며 되돌릴 수 없습니다.\n'
          '본인 확인을 위해 로그인 창이 한 번 더 뜹니다.',
      actionLabel: '탈퇴하기',
      isDanger: true,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await _loginUtil.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((Route<void> r) => r.isFirst);
      return;
    } catch (error) {
      if (!mounted) return;
      final String? message = authErrorMessage(error);
      if (message != null) showToast(context, message);
      setState(() => _isLoading = false);
    }
  }

  /// 되돌릴 수 없는 동작 전에 한 번 더 물어보는 창.
  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
    bool isDanger = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actionsPadding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                '취소',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: isDanger ? AppColors.danger : AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final List<String> linked = _loginUtil.linkedProviderIds();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        // 진행 중일 때만 상단 구분선 자리에 얇은 진행 막대를 띄운다.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: _isLoading
              ? const LinearProgressIndicator(minHeight: 1)
              : const Divider(),
        ),
      ),

      // 처리하는 동안 다른 걸 누르지 못하게 막는다.
      // 연동 도중에 탈퇴를 누르는 식의 상황을 방지한다.
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: ListView(
          children: <Widget>[
            const _SectionHeader('계정'),

            // 연결 여부와 상관없이 두 줄을 항상 같은 자리에 보여준다.
            // 버튼이 나타났다 사라지는 것보다 상태만 바뀌는 쪽이 덜 혼란스럽다.
            for (final _ProviderKind kind in _ProviderKind.values)
              _ProviderTile(
                kind: kind,
                isLinked: linked.contains(kind.providerId),
                onTap: () =>
                    _onProviderTap(kind, linked.contains(kind.providerId)),
              ),

            const _SectionNote('여러 수단을 연결해두면 어느 쪽으로 로그인해도 같은 계정으로 들어옵니다.'),

            const _SectionHeader('정보'),
            _InfoTile(label: '버전', value: kAppVersion),
            _InfoTile(label: '사용자 ID', value: _shortUid(user?.uid)),

            const SizedBox(height: 8),
            const Divider(),

            _ActionTile(label: '로그아웃', onTap: _signOut),
            _ActionTile(
              label: '회원탈퇴',
              color: AppColors.danger,
              onTap: _deleteAccount,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// uid는 그대로 보여주기엔 길어서 앞뒤만 남긴다.
  String _shortUid(String? uid) {
    if (uid == null || uid.length <= 12) return uid ?? '-';
    return '${uid.substring(0, 6)}…${uid.substring(uid.length - 4)}';
  }
}

/// 화면에 보여줄 로그인 수단.
///
/// providerId 문자열('google.com')을 화면 곳곳에 직접 적으면 오타가 나기 쉽고,
/// 이름이나 아이콘을 함께 관리하기도 어렵다. 그래서 하나로 묶었다.
enum _ProviderKind {
  google('Google'),
  apple('Apple');

  const _ProviderKind(this.label);

  /// 화면에 보여줄 이름.
  final String label;

  /// 파이어베이스가 쓰는 식별자. ('google.com', 'apple.com')
  String get providerId => this == _ProviderKind.google
      ? GoogleAuthProvider.PROVIDER_ID
      : AppleAuthProvider.PROVIDER_ID;
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.kind,
    required this.isLinked,
    required this.onTap,
  });

  final _ProviderKind kind;
  final bool isLinked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: kind == _ProviderKind.google
              ? const GoogleLogo(size: 20)
              : const Icon(Icons.apple, size: 24, color: AppColors.text),
        ),
      ),
      title: Text(
        kind.label,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        isLinked ? '연결됨' : '연결되지 않음',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: isLinked
          ? const Icon(Icons.check_circle, size: 20, color: AppColors.accent)
          : const Text(
              '연결하기',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionNote extends StatelessWidget {
  const _SectionNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(color: AppColors.text, fontSize: 15),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.onTap,
    this.color = AppColors.text,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
