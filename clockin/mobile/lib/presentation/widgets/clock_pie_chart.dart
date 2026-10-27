import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/config/theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/clock_task.dart';
import '../../core/state/category_controller.dart';
import '../../core/utils/date_utils.dart';

/// The signature 24-hour clock: today's tasks drawn as tinted arcs around the
/// dial, a "now" hand, and [center] content in the middle. Tap an arc to open
/// that task.
class ClockDial extends StatelessWidget {
  final List<ClockTask> tasks;
  final ClockTask? current;
  final DateTime now;
  final Widget center;
  final ValueChanged<ClockTask>? onTaskTap;

  const ClockDial({
    super.key,
    required this.tasks,
    required this.current,
    required this.now,
    required this.center,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categories = context.watch<CategoryController>();
    final use24h = use24hOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final geometry = _DialGeometry(size);
        return GestureDetector(
          onTapUp: onTaskTap == null
              ? null
              : (d) {
                  final hit = geometry.taskAt(d.localPosition, tasks, current);
                  if (hit != null) onTaskTap!(hit);
                },
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DialPainter(
                      tasks: tasks,
                      current: current,
                      now: now,
                      colors: colors,
                      geometry: geometry,
                      labelStyle: context.tt.labelSmall!,
                      tintOf: (t) => colors.tint(categories.byKey(t.category).color),
                      use24h: use24h,
                    ),
                  ),
                ),
                SizedBox(width: size * 0.42, child: center),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DialGeometry {
  final double size;
  _DialGeometry(this.size);

  double get r => size / 2;
  Offset get center => Offset(r, r);
  double get trackR => r * 0.775;
  double get trackW => r * 0.17;

  static double angleForMinute(num minute) => (minute / 1440) * 2 * math.pi - math.pi / 2;

  ClockTask? taskAt(Offset p, List<ClockTask> tasks, ClockTask? current) {
    final v = p - center;
    final dist = v.distance;
    if ((dist - trackR).abs() > trackW * 0.8) return null;
    final angle = (math.atan2(v.dy, v.dx) + math.pi / 2) % (2 * math.pi);
    final minute = (angle / (2 * math.pi) * 1440).floor();
    final hits = tasks.where((t) => t.coversMinute(minute)).toList();
    if (hits.isEmpty) return null;
    if (current != null && hits.contains(current)) return current;
    return hits.firstWhere((t) => !t.isCompleted, orElse: () => hits.first);
  }
}

class _DialPainter extends CustomPainter {
  final List<ClockTask> tasks;
  final ClockTask? current;
  final DateTime now;
  final AppColors colors;
  final _DialGeometry geometry;
  final TextStyle labelStyle;
  final Color Function(ClockTask) tintOf;
  final bool use24h;

  _DialPainter({
    required this.tasks,
    required this.current,
    required this.now,
    required this.colors,
    required this.geometry,
    required this.labelStyle,
    required this.tintOf,
    required this.use24h,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final c = g.center;
    final r = g.r;

    // Face with a soft center highlight.
    final faceRect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.lerp(colors.dialFace, Colors.white, 0.06)!, colors.dialFace],
          stops: const [0.0, 1.0],
        ).createShader(faceRect),
    );

    // Track behind the task arcs.
    final trackRect = Rect.fromCircle(center: c, radius: g.trackR);
    canvas.drawCircle(
      c,
      g.trackR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.trackW
        ..color = colors.dialTrack,
    );

    // Task arcs: completed dimmed, current glowing.
    for (final t in tasks) {
      final sweep = (math.max(t.durationMinutes, 1) / 1440) * 2 * math.pi;
      final gap = math.min(0.012, sweep * 0.15);
      final start = _DialGeometry.angleForMinute(t.startMinute) + gap;
      final arcSweep = math.max(sweep - gap * 2, 0.002);
      final base = tintOf(t);
      final isCurrent = identical(t, current) && !t.isCompleted;

      if (isCurrent) {
        canvas.drawArc(
          trackRect,
          start,
          arcSweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = g.trackW + 8
            ..color = base.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      canvas.drawArc(
        trackRect,
        start,
        arcSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = g.trackW
          ..color = t.isCompleted ? base.withValues(alpha: 0.28) : (isCurrent ? base : base.withValues(alpha: 0.85)),
      );
      _paintArcLabel(canvas, t, start, arcSweep);
    }

    // Ticks: every 15 minutes, longer each hour, longest every 3 hours.
    for (var i = 0; i < 96; i++) {
      final a = _DialGeometry.angleForMinute(i * 15);
      final isHour = i % 4 == 0;
      final isMajor = i % 12 == 0;
      final inner = r * (isMajor ? 0.885 : (isHour ? 0.915 : 0.95));
      final outer = r * 0.975;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * inner,
        c + Offset(math.cos(a), math.sin(a)) * outer,
        Paint()
          ..color = isHour ? colors.dialTick : colors.dialTick.withValues(alpha: 0.18)
          ..strokeWidth = isMajor ? 2 : 1
          ..strokeCap = StrokeCap.round,
      );
    }

    // Hour labels every 3 hours, inside the track.
    for (var h = 0; h < 24; h += 3) {
      final a = _DialGeometry.angleForMinute(h * 60);
      final tp = TextPainter(
        text: TextSpan(
          text: formatHourLabel(h, use24h: use24h),
          style: labelStyle.copyWith(color: colors.dialLabel, fontWeight: FontWeight.w700, fontSize: r * 0.075),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = c + Offset(math.cos(a), math.sin(a)) * (r * 0.585);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // "Now" hand across the track, ending in a dot on the track.
    final nowA = _DialGeometry.angleForMinute(now.hour * 60 + now.minute + now.second / 60);
    final dir = Offset(math.cos(nowA), math.sin(nowA));
    canvas.drawLine(
      c + dir * (g.trackR - g.trackW / 2 - 6),
      c + dir * (r * 0.975),
      Paint()
        ..color = colors.dialHand
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    final dot = c + dir * g.trackR;
    canvas.drawCircle(dot, 7, Paint()..color = colors.dialFace);
    canvas.drawCircle(dot, 5, Paint()..color = colors.dialHand);
  }

  void _paintArcLabel(Canvas canvas, ClockTask t, double start, double sweep) {
    final g = geometry;
    final arcLength = sweep * g.trackR;
    if (arcLength < 30 || t.title.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: t.title,
        style: labelStyle.copyWith(
          color: t.isCompleted ? colors.dialLabel : colors.onDialArc,
          fontWeight: FontWeight.w800,
          fontSize: math.min(11, g.trackW * 0.42),
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: arcLength * 0.85);

    final mid = start + sweep / 2;
    final pos = g.center + Offset(math.cos(mid), math.sin(mid)) * g.trackR;
    // Keep text reading left-to-right: tangent on the top half, flipped below.
    final rotation = math.sin(mid) > 0 ? mid - math.pi / 2 : mid + math.pi / 2;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => true;
}
