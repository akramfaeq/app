import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _riseCtrl;
  late AnimationController _circleCtrl;
  late AnimationController _nCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _planetCtrl;
  late AnimationController _nameCtrl;
  late AnimationController _loaderCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _exitCtrl;

  late Animation<double> _riseAnim;
  late Animation<double> _riseOpacity;
  late Animation<double> _circleAnim;
  late Animation<double> _nAnim;
  late Animation<double> _ringAnim;
  late Animation<double> _planetAnim;
  late Animation<double> _nameOpacity;
  late Animation<double> _nameSpacing;
  late Animation<double> _loaderOpacity;
  late Animation<double> _loaderFill;
  late Animation<double> _pulseAnim;
  late Animation<double> _exitOpacity;

  static const Color _bgColor    = Color(0xFF000000);
  static const Color _neonPurple = Color(0xFFBF5FFF);
  static const Color _neonSoft   = Color(0xFF9B8FCC);
  static const Color _accentPink = Color(0xFFFF47D4);
  static const Color _textLight  = Color(0xFFF0EEFF);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _riseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _riseAnim = Tween<double>(begin: 20, end: 0).animate(CurvedAnimation(parent: _riseCtrl, curve: Curves.easeOutBack));
    _riseOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _riseCtrl, curve: Curves.easeOut));

    _circleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _circleAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _circleCtrl, curve: Curves.easeInOut));

    _nCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _nAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _nCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    _ringAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));

    _planetCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _planetAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _planetCtrl, curve: Curves.elasticOut));

    _nameCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _nameOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut));
    _nameSpacing = Tween<double>(begin: 10, end: 2).animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut));

    _loaderCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _loaderOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loaderCtrl, curve: const Interval(0, 0.1, curve: Curves.easeOut)),
    );
    _loaderFill = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.8), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1), weight: 40),
    ]).animate(CurvedAnimation(parent: _loaderCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _riseCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _circleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _nCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _nameCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _ringCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _loaderCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _planetCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _pulseCtrl.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    _exitCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    // ── انتقل للصفحة الرئيسية ──
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _riseCtrl.dispose();
    _circleCtrl.dispose();
    _nCtrl.dispose();
    _ringCtrl.dispose();
    _planetCtrl.dispose();
    _nameCtrl.dispose();
    _loaderCtrl.dispose();
    _pulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (context, _) => Opacity(
        opacity: _exitOpacity.value,
        child: Container(
          width: size.width,
          height: size.height,
          color: _bgColor,
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _riseCtrl, _circleCtrl, _nCtrl, _ringCtrl,
                _planetCtrl, _nameCtrl, _loaderCtrl, _pulseCtrl,
              ]),
              builder: (context, _) => Opacity(
                opacity: _riseOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _riseAnim.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── اللوغو ──
                      SizedBox(
                        width: 250, height: 250,
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, _) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: CustomPaint(
                              painter: _MangaLogoPainter(
                                circleProgress: _circleAnim.value,
                                nProgress: _nAnim.value,
                                ringProgress: _ringAnim.value,
                                planetOpacity: _planetAnim.value,
                                neonColor: _neonPurple,
                                ringColor: _neonSoft,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── اسم التطبيق ──
                      Opacity(
                        opacity: _nameOpacity.value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Manga',
                              style: TextStyle(
                                fontFamily: 'Archivo Black',
                                fontSize: 26, fontWeight: FontWeight.w900,
                                color: _textLight,
                                letterSpacing: _nameSpacing.value,
                              )),
                            Text('Nova',
                              style: TextStyle(
                                fontFamily: 'Archivo Black',
                                fontSize: 26, fontWeight: FontWeight.w900,
                                color: _neonPurple,
                                letterSpacing: _nameSpacing.value,
                                shadows: [
                                  Shadow(color: _neonPurple.withOpacity(0.5), blurRadius: 12),
                                ],
                              )),
                          ],
                        ),
                      ),

                      // ── شريط التحميل ──
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: _loaderOpacity.value,
                        child: SizedBox(
                          width: 130,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: Container(
                              height: 3,
                              color: _neonPurple.withOpacity(0.1),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _loaderFill.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF7B4DC8), Color(0xFFBF5FFF), Color(0xFFFF47D4)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: _neonPurple.withOpacity(0.4), blurRadius: 6),
                                    ],
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── CustomPainter ──
class _MangaLogoPainter extends CustomPainter {
  final double circleProgress, nProgress, ringProgress, planetOpacity;
  final Color neonColor, ringColor;

  _MangaLogoPainter({
    required this.circleProgress, required this.nProgress,
    required this.ringProgress, required this.planetOpacity,
    required this.neonColor, required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.25;

    if (circleProgress > 0) {
      final glowPaint = Paint()
        ..color = neonColor.withOpacity(0.45 * circleProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * (size.width / 250)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      _drawArc(canvas, cx, cy, r, circleProgress, glowPaint);

      final mainPaint = Paint()
        ..color = neonColor.withOpacity(circleProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (size.width / 250)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      _drawArc(canvas, cx, cy, r, circleProgress, mainPaint);

      final whitePaint = Paint()
        ..color = Colors.white.withOpacity(0.85 * circleProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * (size.width / 250);
      _drawArc(canvas, cx, cy, r, circleProgress, whitePaint);
    }

    if (nProgress > 0) {
      final scale = size.width / 500;
      final nPath = _buildNPath(scale);
      final nGlow = Paint()
        ..color = neonColor.withOpacity(0.5 * nProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(_clipPath(nPath, nProgress), nGlow);

      final nMid = Paint()
        ..color = const Color(0xFFD899FF).withOpacity(nProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawPath(_clipPath(nPath, nProgress), nMid);

      final nWhite = Paint()
        ..color = Colors.white.withOpacity(nProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_clipPath(nPath, nProgress), nWhite);
    }

    if (ringProgress > 0) {
      final scale = size.width / 500;
      final ringRect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: 160 * 2 * scale,
        height: 38 * 2 * scale,
      );
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(-20 * math.pi / 180);
      canvas.translate(-cx, -cy);

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, cy));
      _drawEllipseArc(canvas, ringRect, ringProgress, ringColor, scale, back: true);
      canvas.restore();

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, cy, size.width, size.height));
      _drawEllipseArc(canvas, ringRect, ringProgress, ringColor, scale, back: false);
      canvas.restore();

      canvas.restore();
    }

    if (planetOpacity > 0) {
      final scale = size.width / 500;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(-20 * math.pi / 180);
      canvas.translate(-cx, -cy);
      _drawPlanet(canvas, Offset(410 * scale, cy), 15 * scale, planetOpacity, scale);
      canvas.restore();
    }
  }

  void _drawArc(Canvas canvas, double cx, double cy, double r, double progress, Paint paint) {
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  Path _buildNPath(double scale) {
    final path = Path();
    path.moveTo(200 * scale, 325 * scale);
    path.lineTo(200 * scale, 190 * scale);
    path.cubicTo(200 * scale, 168 * scale, 218 * scale, 166 * scale, 228 * scale, 183 * scale);
    path.lineTo(272 * scale, 317 * scale);
    path.cubicTo(282 * scale, 334 * scale, 300 * scale, 332 * scale, 300 * scale, 310 * scale);
    path.lineTo(300 * scale, 175 * scale);
    return path;
  }

  Path _clipPath(Path original, double progress) {
    if (progress >= 1) return original;
    final metrics = original.computeMetrics();
    final result = Path();
    for (final metric in metrics) {
      result.addPath(metric.extractPath(0, metric.length * progress), Offset.zero);
    }
    return result;
  }

  void _drawEllipseArc(Canvas canvas, Rect rect, double progress, Color color, double scale, {required bool back}) {
    final glow = Paint()
      ..color = color.withOpacity(0.4 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(rect, 0, 2 * math.pi * progress, false, glow);

    final soft = Paint()
      ..color = color.withOpacity(progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawArc(rect, 0, 2 * math.pi * progress, false, soft);

    final white = Paint()
      ..color = Colors.white.withOpacity(0.85 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawArc(rect, 0, 2 * math.pi * progress, false, white);
  }

  void _drawPlanet(Canvas canvas, Offset center, double r, double opacity, double scale) {
    final atmGrad = RadialGradient(
      center: const Alignment(0.3, -0.3), radius: 0.6,
      colors: [
        const Color(0xFF8a99e1).withOpacity(0),
        const Color(0xFF9B8FCC).withOpacity(0.3 * opacity),
        const Color(0xFFBF5FFF).withOpacity(0.5 * opacity),
      ],
      stops: const [0.6, 0.9, 1.0],
    );
    canvas.drawCircle(center, r * 1.2,
        Paint()..shader = atmGrad.createShader(Rect.fromCircle(center: center, radius: r * 1.2)));

    final planetGrad = RadialGradient(
      center: const Alignment(0.4, -0.4), radius: 0.7,
      colors: const [Color(0xFF9bb0d3), Color(0xFF4d587a), Color(0xFF1f1a38), Color(0xFF080512)],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    canvas.drawCircle(center, r,
        Paint()..shader = planetGrad.createShader(Rect.fromCircle(center: center, radius: r)));

    final shadowPath = Path()..addArc(Rect.fromCircle(center: center, radius: r), 0, math.pi);
    canvas.drawPath(shadowPath,
        Paint()..color = const Color(0xFF04020a).withOpacity(0.85 * opacity));
  }

  @override
  bool shouldRepaint(_MangaLogoPainter old) =>
      old.circleProgress != circleProgress || old.nProgress != nProgress ||
      old.ringProgress != ringProgress || old.planetOpacity != planetOpacity;
}
