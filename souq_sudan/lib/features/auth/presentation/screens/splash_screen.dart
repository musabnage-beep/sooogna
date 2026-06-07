import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

/// Cinematic onboarding sequence — a single 60 FPS timeline that takes the user
/// "into the marketplace through Sudan":
///   1. Pure black screen.
///   2. Sudan outline draws on with a glowing orange neon stroke (~1.5s).
///   3. A location pin pops in at the country's centre (scale 0→1, bounce).
///   4. The pin emits three expanding orange ripple waves (~1s).
///   5. The pin rapidly zooms 1x→full-screen (~0.8s) — the portal.
///   6. At full cover the screen is solid orange and we hand off to Home,
///      so it reads as entering the marketplace from inside the pin.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Master timeline. Stage boundaries (as fractions of total) below.
  static const _total = Duration(milliseconds: 3800);

  // Stage intervals on the master controller (0..1).
  static const _mapStart = 0.0, _mapEnd = 0.40; // 1520ms draw-on
  static const _pinStart = 0.40, _pinEnd = 0.55; // 570ms pop
  static const _rippleStart = 0.55, _rippleEnd = 0.80; // 950ms waves
  static const _zoomStart = 0.80, _zoomEnd = 1.0; // 760ms portal

  static const _orange = Color(0xFFFF7A00);
  static const _gold = Color(0xFFFFB000);

  late final AnimationController _c;

  late final Animation<double> _mapDraw; // 0→1 progressive outline
  late final Animation<double> _pinScale; // 0→1 bounce
  late final Animation<double> _pinFade; // 0→1 then →0 on zoom
  late final Animation<double> _ripple; // 0→1 wave driver
  late final Animation<double> _rippleFade; // ripples fade out on zoom
  late final Animation<double> _zoom; // 0→1 portal expansion
  late final Animation<double> _mapFade; // outline fades as portal opens

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _total);

    _mapDraw = CurvedAnimation(
      parent: _c,
      curve: const Interval(_mapStart, _mapEnd, curve: Curves.easeInOut),
    );

    _pinScale = CurvedAnimation(
      parent: _c,
      curve: const Interval(_pinStart, _pinEnd, curve: Curves.elasticOut),
    );

    _pinFade = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: _pinStart * 100),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: (_pinEnd - _pinStart) * 100,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: (_zoomStart - _pinEnd) * 100,
      ),
      // Quickly hand the visual over to the solid portal disc.
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 3,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 17),
    ]).animate(_c);

    _ripple = CurvedAnimation(
      parent: _c,
      curve: const Interval(_rippleStart, _rippleEnd, curve: Curves.linear),
    );

    _rippleFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(_zoomStart, 0.88, curve: Curves.easeOut),
      ),
    );

    _zoom = CurvedAnimation(
      parent: _c,
      curve: const Interval(_zoomStart, _zoomEnd, curve: Curves.easeInCubic),
    );

    _mapFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(_zoomStart, 0.92, curve: Curves.easeIn),
      ),
    );

    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _navigate();
    });
    _c.forward();
  }

  Future<void> _navigate() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/home');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Portal disc base diameter; scale needed to cover the whole screen.
    const discBase = 70.0;
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    final maxScale = (diagonal / discBase) * 1.15;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Sudan outline (neon, progressively drawn) — fades on portal.
              Opacity(
                opacity: _mapFade.value,
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: CustomPaint(
                    painter: _SudanMapPainter(progress: _mapDraw.value),
                  ),
                ),
              ),

              // Expanding ripple waves from the pin.
              if (_ripple.value > 0 && _rippleFade.value > 0)
                Opacity(
                  opacity: _rippleFade.value,
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: CustomPaint(
                      painter: _RipplePainter(t: _ripple.value),
                    ),
                  ),
                ),

              // The location pin (decorative, with tail) for stages 3–4.
              if (_pinFade.value > 0)
                Opacity(
                  opacity: _pinFade.value,
                  child: Transform.scale(
                    scale: _pinScale.value.clamp(0.0, 1.4),
                    child: const _LocationPin(),
                  ),
                ),

              // Portal disc — takes over from the pin head and zooms to fill.
              if (_zoom.value > 0)
                Transform.scale(
                  scale: 1 + (_zoom.value * (maxScale - 1)),
                  child: Container(
                    width: discBase,
                    height: discBase,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _orange,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Decorative teardrop pin with a glowing head used during the pop + ripple.
class _LocationPin extends StatelessWidget {
  const _LocationPin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 116,
      child: CustomPaint(
        painter: _PinPainter(),
        child: Align(
          alignment: const Alignment(0, -0.32),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF120A02),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: _SplashScreenState._gold,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  static const _orange = Color(0xFFFF7A00);
  static const _gold = Color(0xFFFFB000);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final radius = size.width * 0.40;
    final pinTop = size.height * 0.04;
    final circleCenter = pinTop + radius;

    // Neon glow halo around the head.
    final glow = Paint()
      ..color = _orange.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(cx, circleCenter), radius + 6, glow);

    final fill = Paint()..color = _orange;

    // Tail.
    final tailW = radius * 0.55;
    final tail = Path()
      ..moveTo(cx - tailW, circleCenter + radius * 0.55)
      ..lineTo(cx + tailW, circleCenter + radius * 0.55)
      ..lineTo(cx, size.height * 0.92)
      ..close();
    canvas.drawPath(tail, fill);

    // Head.
    canvas.drawCircle(Offset(cx, circleCenter), radius, fill);

    // Inner ring accent.
    final ring = Paint()
      ..color = _gold.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, circleCenter), radius - 5, ring);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) => false;
}

/// Three outward-expanding orange ripple rings.
class _RipplePainter extends CustomPainter {
  final double t; // 0..1
  _RipplePainter({required this.t});

  static const _orange = Color(0xFFFF7A00);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const minR = 26.0;
    final maxR = size.width * 0.46;

    for (var i = 0; i < 3; i++) {
      // Stagger the three waves across the timeline.
      var phase = t - (i * 0.28);
      if (phase <= 0 || phase > 1) continue;
      final r = minR + (maxR - minR) * phase;
      final alpha = (1 - phase) * 0.6;
      final paint = Paint()
        ..color = _orange.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => oldDelegate.t != t;
}

/// Sudan silhouette drawn progressively with a glowing neon stroke.
class _SudanMapPainter extends CustomPainter {
  final double progress; // 0..1 fraction of the outline drawn
  _SudanMapPainter({required this.progress});

  static const _orange = Color(0xFFFF7A00);

  // Sudan's real outline, traced clockwise from the NW (Egypt/Libya) corner.
  // Coordinates are normalised from actual lon/lat into a unit box, so the
  // silhouette is geographically faithful (straight northern Egypt border,
  // Red Sea coast & Hala'ib jut on the NE, Darfur bulge on the W, the
  // South-Sudan/Ethiopia frontier along the bottom).
  static const List<Offset> _unit = [
    Offset(0.181, 0.000), // NW corner (Egypt/Libya tripoint)
    Offset(0.572, 0.000), // straight northern border
    Offset(0.675, 0.000),
    Offset(0.904, 0.000), // toward Hala'ib
    Offset(0.916, 0.079), // Red Sea coast begins
    Offset(0.904, 0.197),
    Offset(1.000, 0.315), // coastal bulge (Port Sudan)
    Offset(0.988, 0.394),
    Offset(0.934, 0.417), // Eritrea border inland
    Offset(0.873, 0.551), // Kassala
    Offset(0.855, 0.630),
    Offset(0.783, 0.748), // Gedaref / Ethiopia
    Offset(0.741, 0.882), // Blue Nile
    Offset(0.717, 0.984), // SE corner
    Offset(0.675, 0.961),
    Offset(0.627, 0.866),
    Offset(0.422, 0.969), // South Sudan frontier
    Offset(0.331, 1.000),
    Offset(0.241, 0.984),
    Offset(0.120, 0.945), // CAR / Chad tripoint
    Offset(0.090, 0.827),
    Offset(0.030, 0.709),
    Offset(0.000, 0.591), // westernmost (Darfur)
    Offset(0.060, 0.472),
    Offset(0.120, 0.315), // W border climbing back north
    Offset(0.120, 0.157),
  ];

  // Real width:height ratio of Sudan's bounding box (≈16.6° lon / 12.7° lat).
  static const double _aspect = 16.6 / 12.7;

  Path _sudanPath(Size size) {
    // Fit the unit outline into [size] preserving the real aspect ratio,
    // then centre it.
    double drawW, drawH;
    if (size.width / size.height > _aspect) {
      drawH = size.height;
      drawW = drawH * _aspect;
    } else {
      drawW = size.width;
      drawH = drawW / _aspect;
    }
    final dx = (size.width - drawW) / 2;
    final dy = (size.height - drawH) / 2;

    final path = Path();
    for (var i = 0; i < _unit.length; i++) {
      final o = Offset(dx + _unit[i].dx * drawW, dy + _unit[i].dy * drawH);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final full = _sudanPath(size);

    // Extract the drawn-so-far sub-path.
    final metrics = full.computeMetrics().toList();
    final totalLen = metrics.fold<double>(0, (s, m) => s + m.length);
    final target = totalLen * progress;
    final drawn = Path();
    var acc = 0.0;
    for (final m in metrics) {
      if (acc >= target) break;
      final remaining = target - acc;
      final end = remaining < m.length ? remaining : m.length;
      drawn.addPath(m.extractPath(0, end), Offset.zero);
      acc += m.length;
    }

    // Soft fill builds up once mostly drawn.
    if (progress > 0.85) {
      final fillA = ((progress - 0.85) / 0.15).clamp(0.0, 1.0) * 0.10;
      canvas.drawPath(full, Paint()..color = _orange.withValues(alpha: fillA));
    }

    // Outer bloom (very wide, soft) for a cinematic neon halo.
    final bloom = Paint()
      ..color = _orange.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawPath(drawn, bloom);

    // Inner glow (wide, blurred) under the crisp stroke.
    final glow = Paint()
      ..color = _orange.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(drawn, glow);

    // Crisp neon line.
    final line = Paint()
      ..color = _orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(drawn, line);
  }

  @override
  bool shouldRepaint(covariant _SudanMapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
