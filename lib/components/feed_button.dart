import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet_track/core/app_colors.dart';

// Aquest fitxer conté el widget del botó d'alimentació, que permet registrar una
// nova ració de menjar per a la mascota de manera visual i interactiva.

class FeedButton extends StatefulWidget {
  final double size;
  final int dailyFeedCount;
  final int dailyFeedGoal;
  final DateTime lastFed;
  final void Function(bool) onFeed;

  const FeedButton({
    super.key,
    required this.size,
    required this.dailyFeedCount,
    required this.dailyFeedGoal,
    required this.lastFed,
    required this.onFeed,
  });

  @override
  State<FeedButton> createState() => _FeedButtonState();
}

class _FeedButtonState extends State<FeedButton> {
  late int _count;
  late DateTime _lastFed;

  @override
  void initState() {
    super.initState();
    _count = widget.dailyFeedCount;
    _lastFed = widget.lastFed;
  }

  void _handleFeed(bool add) {
    if (_count < widget.dailyFeedGoal) {
      widget.onFeed(add);
      setState(() {
        if (add) {
          _lastFed = DateTime.now();
          _count = _count + 1;
        } else {
          _count = max(_count - 1, 0);
        }
      });
    }
  }

  bool get _isBowlEmpty => DateTime.now().difference(_lastFed).inMinutes >= 10;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleFeed(true),
      onLongPress: () => _handleFeed(false),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CircleProgressPainter(
                filledSegments: _count,
                segments: widget.dailyFeedGoal,
              ),
            ),
            SvgPicture.asset(
              !_isBowlEmpty || _count == widget.dailyFeedGoal
                  ? 'assets/images/full_bowl.svg'
                  : 'assets/images/empty_bowl.svg',
              width: widget.size * 0.5,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final int filledSegments;
  final int segments;

  _CircleProgressPainter({
    required this.filledSegments,
    required this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint =
        Paint()
          ..color = Colors.black.withAlpha((255 * 0.1).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

    final fgPaint =
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(center, radius, bgPaint);

    if (segments <= 0) return;

    final gapAngle = 2 * pi * 0.015;
    final segmentAngle = (2 * pi / segments) - gapAngle;

    for (int i = 0; i < segments; i++) {
      final startAngle = (2 * pi * i / segments) - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
        i < filledSegments ? fgPaint : bgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter old) =>
      old.filledSegments != filledSegments || old.segments != segments;
}
