import 'package:flutter/material.dart';

/// 화면에 보이는 앱 이름.
///
/// 여기 한 곳만 바꾸면 로그인 화면 로고와 홈 상단 이름이 같이 바뀐다.
const String kAppName = 'Aurora';

/// 앱에서 쓰는 색을 한곳에 모아둔 곳.
///
/// 화면마다 색을 직접 적어두면 나중에 톤을 바꿀 때 전부 찾아다녀야 한다.
/// 이름으로 부르게 해두면 여기 값만 고쳐도 앱 전체가 따라 바뀐다.
class AppColors {
  const AppColors._();

  /// 기본 배경. 흰 배경에 여백을 넉넉히 주는 게 이 디자인의 핵심이다.
  static const Color background = Color(0xFFFFFFFF);

  /// 카드나 아바타 배경처럼 살짝만 눌러줄 때 쓰는 회색.
  static const Color surface = Color(0xFFFAFAFA);

  /// 본문 글자색.
  static const Color text = Color(0xFF000000);

  /// 설명글처럼 덜 중요한 글자색.
  static const Color textSecondary = Color(0xFF737373);

  /// 1픽셀 구분선 색.
  static const Color separator = Color(0xFFDBDBDB);

  /// 링크나 강조 버튼에 쓰는 파랑.
  static const Color accent = Color(0xFF0095F6);

  /// 회원탈퇴처럼 되돌릴 수 없는 동작에 쓰는 빨강.
  static const Color danger = Color(0xFFED4956);

  /// 로고 마크에 쓰는 그라데이션.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF6C5CE7), Color(0xFFB14BF4), Color(0xFF4FACFE)],
  );
}

/// 앱 전체에 적용되는 테마.
///
/// 버튼 모서리, 글자 크기 같은 걸 화면마다 따로 적지 않고 여기서 한 번에 정한다.
class AppTheme {
  const AppTheme._();

  /// 버튼과 입력창의 높이. 손가락으로 누르기 편한 크기다.
  static const double controlHeight = 52;

  /// 버튼 모서리 둥글기.
  static const double radius = 12;

  /// 화면 좌우 여백.
  static const double pagePadding = 24;

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ).copyWith(surface: AppColors.background, error: AppColors.danger);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,

      // 상단바는 흰 배경에 그림자 없이. 구분선은 화면마다 직접 그린다.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.separator,
        thickness: 0.5,
        space: 0.5,
      ),

      // 안내 메시지는 화면에 글자로 박아두지 않고 아래에서 잠깐 떴다 사라지게 한다.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF262626),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      textTheme: const TextTheme(
        titleMedium: TextStyle(
          color: AppColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: AppColors.text, fontSize: 15),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}

/// 앱 이름을 보여주는 로고 글자.
///
/// 로그인 화면과 홈 상단에서 크기만 다르게 해서 같이 쓴다.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.fontSize = 22});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      kAppName,
      style: TextStyle(
        color: AppColors.text,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        // 자간을 살짝 좁히면 글자가 하나의 덩어리처럼 보여서 로고 느낌이 난다.
        letterSpacing: -fontSize * 0.03,
      ),
    );
  }
}

/// 로고 마크. 둥근 사각형 안에 그라데이션을 채운 형태다.
///
/// 이미지 파일을 쓰지 않고 코드로 그리기 때문에 에셋을 따로 넣을 필요가 없다.
/// 실제 출시할 때는 여기를 직접 만든 로고 이미지로 바꾸면 된다.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.45),
    );
  }
}
