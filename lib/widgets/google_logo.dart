import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 구글 로그인 버튼에 들어가는 'G' 마크.
///
/// 이미지 파일 없이 코드로 그린다. 에셋을 안 넣어도 되고,
/// 어떤 화면 밀도에서도 깨지지 않는다는 게 장점이다.
///
/// TODO: [정식 출시용]
/// 스토어에 올릴 앱이라면 구글이 배포하는 공식 로고 파일을 쓰는 게 원칙이다.
/// (Google Identity 브랜딩 가이드라인에 버튼 이미지가 같이 들어 있다.)
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const Color _blue = Color(0xFF4285F4);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _red = Color(0xFFEA4335);

  /// 도(度)로 적어둔 각도를 라디안으로 바꾼다.
  ///
  /// 플러터는 3시 방향이 0도이고, 시계 방향으로 각도가 커진다.
  double _rad(double degree) => degree * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    final Offset center = Offset(size.width / 2, size.height / 2);

    // 고리의 두께와 반지름. 로고 원본 비율(48 크기 기준)을 그대로 옮겨왔다.
    final double stroke = side * 0.1875;
    final double radius = side * 0.3646;

    final Rect ring = Rect.fromCircle(center: center, radius: radius);

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // 고리를 네 조각으로 나눠서 각각 다른 색으로 칠한다.
    // 오른쪽 위가 비어 있는 건 원래 로고에 있는 틈이다.
    void drawArc(Color color, double startDegree, double sweepDegree) {
      canvas.drawArc(
        ring,
        _rad(startDegree),
        _rad(sweepDegree),
        false,
        arc..color = color,
      );
    }

    drawArc(_blue, -11, 60); // 오른쪽
    drawArc(_green, 49, 104); // 아래
    drawArc(_yellow, 153, 54); // 왼쪽
    drawArc(_red, 207, 105); // 위

    // 가운데에서 오른쪽으로 뻗은 가로 막대. 파란색 부분과 이어진다.
    final double barHeight = side * 0.177;
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - barHeight / 2,
        center.dx + radius + stroke / 2,
        center.dy + barHeight / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
