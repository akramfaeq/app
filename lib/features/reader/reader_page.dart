import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/manga_model.dart';
import '../../models/chapter_model.dart';
import '../../services/reading_progress_service.dart';

// ═══════════════════════════════════════════════════════════════
//  ReaderPage — قارئ المانغا
//  ✅ أزرار السابق/التالي: سهم chevron بسيط (بدل nav-btn)
//  ✅ قائمة الفصول: تفتح بالضغط على العنوان فقط (بدون badge)
//  ✅ شريط التقدم: أنبوب زجاجي شفاف + ذهبي (نفس الأصل)
// ═══════════════════════════════════════════════════════════════

enum ReadingMode { vertical, horizontal }

class ReaderPage extends StatefulWidget {
  final MangaModel manga;
  final List<ChapterModel> allChapters; // مرتبة تصاعدياً
  final int initialChapterIndex;
  final int initialPageIndex;

  const ReaderPage({
    super.key,
    required this.manga,
    required this.allChapters,
    required this.initialChapterIndex,
    this.initialPageIndex = 0,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {

  late int _chapterIdx;
  ReadingMode _mode = ReadingMode.vertical;
  bool _barsVisible = true;
  double _progress  = 0.0;
  bool _chaptersDropOpen = false;
  int _currentPageIndex = 0;

  final _vertScrollCtrl  = ScrollController();
  final _horizScrollCtrl = ScrollController();
  Timer? _hideTimer;

  // ── عداد وقت القراءة ──
  Timer? _readingTimer;
  int _secondsRead = 0;
  static const _minSeconds = 9;      // الحد الأدنى للحفظ
  static const _maxProgress = 0.95;  // ما نحفظ إذا اكتمل 95%

  ChapterModel get _chapter => widget.allChapters[_chapterIdx];
  bool get _hasPrev => _chapterIdx > 0;
  bool get _hasNext => _chapterIdx < widget.allChapters.length - 1;

  // ─── ألوان (نفس الأصل) ───
  static const _topbarColor = Color(0xBF0A0514);   // rgba(10,5,20,0.75)
  static const _dropBgColor = Color(0xF70E0814);   // rgba(14,8,24,0.97)
  static const _goldColor   = Color(0xFFE8B85C);
  static const _accentColor = Color(0xFF9B5CF6);
  static const _textPrimary = Color(0xFFE2DEF0);
  static const _textSub     = Color(0x80FFFFFF);

  // ══════════════ init / dispose ══════════════

  @override
  void initState() {
    super.initState();
    _chapterIdx = widget.initialChapterIndex;
    _currentPageIndex = widget.initialPageIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _vertScrollCtrl.addListener(_onVerticalScroll);
    _horizScrollCtrl.addListener(_onHorizontalScroll);
    _startHideTimer();
    _startReadingTimer();

    // اذا فيه صفحة محفوظة، اسكرول لها بعد البناء
    if (widget.initialPageIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pages = _chapter.pageUrls;
        if (pages.isEmpty) return;
        final pct = widget.initialPageIndex / (pages.length - 1).clamp(1, pages.length);
        if (_mode == ReadingMode.vertical && _vertScrollCtrl.hasClients) {
          final max = _vertScrollCtrl.position.maxScrollExtent;
          _vertScrollCtrl.jumpTo((pct * max).clamp(0, max));
        } else if (_horizScrollCtrl.hasClients) {
          final max = _horizScrollCtrl.position.maxScrollExtent;
          _horizScrollCtrl.jumpTo((pct * max).clamp(0, max));
        }
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _vertScrollCtrl.dispose();
    _horizScrollCtrl.dispose();
    _hideTimer?.cancel();
    _readingTimer?.cancel();
    super.dispose();
  }

  // ══════════════ Scroll ══════════════

  void _onVerticalScroll() {
    if (_mode != ReadingMode.vertical) return;
    final max = _vertScrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    final pct = (_vertScrollCtrl.offset / max).clamp(0.0, 1.0);
    if ((_progress - pct).abs() > 0.002) setState(() {
      _progress = pct;
      final len = _chapter.pageUrls.length;
      if (len > 0) _currentPageIndex = (pct * (len - 1)).round().clamp(0, len - 1);
    });

    final dir = _vertScrollCtrl.position.userScrollDirection;
    if (dir == ScrollDirection.reverse) {
      _hideBars();
    } else if (dir == ScrollDirection.forward) {
      _showBars();
    }
  }

  void _onHorizontalScroll() {
    if (_mode != ReadingMode.horizontal) return;
    final max = _horizScrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    final pct = (_horizScrollCtrl.offset / max).clamp(0.0, 1.0);
    if ((_progress - pct).abs() > 0.002) setState(() {
      _progress = pct;
      final len = _chapter.pageUrls.length;
      if (len > 0) _currentPageIndex = (pct * (len - 1)).round().clamp(0, len - 1);
    });
  }

  // ══════════════ Reading Timer ══════════════

  void _startReadingTimer() {
    _secondsRead = 0;
    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsRead++;
      if (_secondsRead >= _minSeconds) {
        _trySaveProgress();
      }
    });
  }

  void _trySaveProgress() {
    // لا تحفظ إذا وصل 95% أو أكثر (اكتمل الفصل)
    if (_progress >= _maxProgress) return;

    final pages = _chapter.pageUrls;
    if (pages.isEmpty) return;

    final pageIdx = _currentPageIndex.clamp(0, pages.length - 1);
    final pageUrl = pages[pageIdx];

    ReadingProgressService.save(ReadingProgress(
      mangaId: widget.manga.id,
      mangaTitle: widget.manga.title,
      mangaCover: widget.manga.cover,
      chapterId: _chapter.number.toString(),
      chapterNumber: _chapter.number,
      totalChapters: widget.manga.chaptersCount,
      pageIndex: pageIdx,
      pageUrl: pageIdx < pages.length ? pages[pageIdx] : '',
      progress: _progress,
      savedAt: DateTime.now(),
    ));
  }

  void _showBars() {
    if (!mounted) return;
    setState(() => _barsVisible = true);
    _startHideTimer();
  }

  void _hideBars() {
    if (!mounted) return;
    _hideTimer?.cancel();
    setState(() => _barsVisible = false);
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), _hideBars);
  }

  void _onTap() {
    if (_chaptersDropOpen) {
      setState(() => _chaptersDropOpen = false);
      return;
    }
    if (_barsVisible) { _hideBars(); } else { _showBars(); }
  }

  // ══════════════ Navigation ══════════════

  void _goToChapter(int newIdx) {
    if (newIdx < 0 || newIdx >= widget.allChapters.length) return;
    setState(() {
      _chapterIdx       = newIdx;
      _progress         = 0.0;
      _currentPageIndex = 0;
      _chaptersDropOpen = false;
    });
    _startReadingTimer(); // ابدأ العداد من جديد للفصل الجديد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mode == ReadingMode.vertical && _vertScrollCtrl.hasClients) {
        _vertScrollCtrl.jumpTo(0);
      } else if (_mode == ReadingMode.horizontal && _horizScrollCtrl.hasClients) {
        _horizScrollCtrl.jumpTo(0);
      }
    });
    _showBars();
  }

  void _goChapterDir(String dir) {
    if (dir == 'prev') {
      if (!_hasPrev) { Navigator.pop(context); return; }
      _goToChapter(_chapterIdx - 1);
    } else {
      if (!_hasNext) return;
      _goToChapter(_chapterIdx + 1);
    }
  }

  void _toggleMode() {
    final savedPage = _currentPageIndex;
    setState(() {
      _mode = _mode == ReadingMode.vertical
          ? ReadingMode.horizontal : ReadingMode.vertical;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final len = _chapter.pageUrls.length;
      if (len == 0) return;
      final pct = savedPage / (len - 1).clamp(1, len);
      if (_mode == ReadingMode.vertical && _vertScrollCtrl.hasClients) {
        final max = _vertScrollCtrl.position.maxScrollExtent;
        _vertScrollCtrl.jumpTo((pct * max).clamp(0, max));
      } else if (_mode == ReadingMode.horizontal && _horizScrollCtrl.hasClients) {
        final max = _horizScrollCtrl.position.maxScrollExtent;
        _horizScrollCtrl.jumpTo((pct * max).clamp(0, max));
      }
    });
    _showBars();
  }

  // ══════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onTap,
        child: Stack(
          children: [
            // ── صفحات ──
            _mode == ReadingMode.vertical ? _buildVertical() : _buildHorizontal(),

            // ── overlay يغلق القائمة ──
            if (_chaptersDropOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _chaptersDropOpen = false),
                  child: Container(color: Colors.transparent),
                ),
              ),

            // ── قائمة الفصول ──
            if (_chaptersDropOpen) _buildChaptersDropdown(),

            // ── TopBar ──
            _buildTopBar(),

            // ── شريط التقدم الزجاجي الذهبي ──
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  // ══════════════ الوضع العمودي ══════════════

  Widget _buildVertical() {
    final pages = _chapter.pageUrls;
    if (pages.isEmpty) {
      return const Center(
        child: Text('لا توجد صفحات لهذا الفصل',
            style: TextStyle(color: _textSub, fontSize: 14)),
      );
    }
    return ListView.builder(
      controller: _vertScrollCtrl,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 56, bottom: 60),
      itemCount: pages.length,
      itemBuilder: (ctx, i) => _PageImage(url: pages[i]),
    );
  }

  // ══════════════ الوضع الأفقي ══════════════

  Widget _buildHorizontal() {
    final pages = _chapter.pageUrls;
    if (pages.isEmpty) {
      return const Center(
        child: Text('لا توجد صفحات', style: TextStyle(color: _textSub, fontSize: 14)),
      );
    }
    final size = MediaQuery.of(context).size;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        controller: _horizScrollCtrl,
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
        itemCount: pages.length,
        itemBuilder: (ctx, i) => SizedBox(
          width: size.width, height: size.height,
          child: _PageImage(url: pages[i], fit: BoxFit.contain, fillH: size.height),
        ),
      ),
    );
  }

  // ══════════════ TopBar ══════════════
  // ✅ أزرار السابق/التالي: chevron شفاف بسيط (بدل دائرة بنفسجية)
  // ✅ العنوان قابل للضغط لفتح القائمة (بدون badge منفصل)

  Widget _buildTopBar() {
    final isHoriz = _mode == ReadingMode.horizontal;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _barsVisible ? 0 : -72,
      left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: _topbarColor,
              border: Border(bottom: BorderSide(color: Color(0x269B28FF), width: 1)),
            ),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [

                // ── زر السابق (يسار) — باهت إذا أول فصل ──
                _NavBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _goChapterDir('prev'),
                  faded: !_hasPrev,
                ),

                // ── العنوان (يفتح قائمة الفصول، بدون سهم) ──
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _chaptersDropOpen = !_chaptersDropOpen);
                    },
                    child: Text(
                      widget.manga.title,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // ── زر تبديل الوضع ──
                GestureDetector(
                  onTap: _toggleMode,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHoriz
                          ? const Color(0x38BB5FF6)
                          : const Color(0x12FFFFFF),
                      border: Border.all(
                        color: isHoriz
                            ? const Color(0x99BB5FF6)
                            : const Color(0x26FFFFFF),
                      ),
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        turns: isHoriz ? 0.25 : 0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        child: const _ModeIcon(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ── زر التالي (يمين) — باهت إذا آخر فصل ──
                _NavBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _goChapterDir('next'),
                  faded: !_hasNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════ شريط التقدم الزجاجي (نفس الأصل) ══════════════
  // أنبوب زجاجي: خلفية شفافة + border أبيض خفيف + fill ذهبي

  Widget _buildProgressBar() {
    final total = _chapter.pageUrls.length;
    final current = total > 0 ? _currentPageIndex + 1 : 0;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _barsVisible ? 0 : -44,
      left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children: [
            // ── عداد الصفحات ──
            Text(
              '$current / $total',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _goldColor,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 10),
            // ── شريط التقدم الزجاجي ──
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(_goldColor),
                      minHeight: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════ قائمة الفصول المنسدلة ══════════════

  Widget _buildChaptersDropdown() {
    final sorted = widget.allChapters.reversed.toList();
    return Positioned(
      top: 56, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            decoration: const BoxDecoration(
              color: _dropBgColor,
              border: Border(bottom: BorderSide(color: Color(0x409B28FF), width: 1)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              shrinkWrap: true,
              itemCount: sorted.length,
              itemBuilder: (ctx, i) {
                final ch = sorted[i];
                final isCurrent = ch.number == _chapter.number;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final realIdx = widget.allChapters
                        .indexWhere((c) => c.number == ch.number);
                    if (realIdx != -1) _goToChapter(realIdx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0x339B28FF)
                          : const Color(0x08FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0x729B28FF)
                            : const Color(0x10FFFFFF),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الفصل ${ch.number}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? const Color(0xFFC9B6F5) : _textPrimary,
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            width: 7, height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  _NavBtn — زر السابق/التالي
//  بنفسجي دائماً — شفاف (faded) عند أول/آخر فصل
// ═══════════════════════════════════════════════════════
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool faded; // أول أو آخر فصل → شفاف

  const _NavBtn({
    required this.icon,
    required this.onTap,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: faded
              ? const Color(0x4D9B5CF6)   // بنفسجي شفاف
              : const Color(0xFF9B5CF6),   // بنفسجي كامل
          boxShadow: faded ? null : const [
            BoxShadow(color: Color(0x809B3CF6), blurRadius: 12),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  _ModeIcon — أيقونة السهمين (نفس الأصل: سهم أعلى + أسفل)
// ═══════════════════════════════════════════════════════
class _ModeIcon extends StatelessWidget {
  const _ModeIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _ModeIconPainter(),
    );
  }
}

class _ModeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;

    // خط عمودي
    canvas.drawLine(Offset(cx, size.height * 0.79), Offset(cx, size.height * 0.21), paint);
    // سهم للأعلى
    canvas.drawLine(Offset(cx - 5, size.height * 0.38), Offset(cx, size.height * 0.21), paint);
    canvas.drawLine(Offset(cx + 5, size.height * 0.38), Offset(cx, size.height * 0.21), paint);
    // سهم للأسفل
    canvas.drawLine(Offset(cx - 5, size.height * 0.62), Offset(cx, size.height * 0.79), paint);
    canvas.drawLine(Offset(cx + 5, size.height * 0.62), Offset(cx, size.height * 0.79), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════
//  _PageImage — صورة صفحة واحدة
//  blur → sharp عند التحميل (نفس filter:blur الأصل)
// ═══════════════════════════════════════════════════════
class _PageImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? fillH;

  const _PageImage({required this.url, this.fit = BoxFit.fitWidth, this.fillH});

  @override
  State<_PageImage> createState() => _PageImageState();
}

class _PageImageState extends State<_PageImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blurCtrl;
  late final Animation<double> _blurAnim;

  @override
  void initState() {
    super.initState();
    _blurCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _blurAnim = Tween<double>(begin: 6.0, end: 0.0).animate(
      CurvedAnimation(parent: _blurCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _blurCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.url,
      fit: widget.fit,
      width: double.infinity,
      height: widget.fillH,
      placeholder: (_, __) => Container(
        color: const Color(0xFF111111),
        height: widget.fillH ?? 300,
        child: const Center(
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF9B5CF6),
            ),
          ),
        ),
      ),
      imageBuilder: (ctx, imageProvider) {
        _blurCtrl.forward();
        return AnimatedBuilder(
          animation: _blurAnim,
          builder: (_, child) {
            final sigma = _blurAnim.value;
            if (sigma < 0.1) return child!;
            return ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: child,
            );
          },
          child: Image(
            image: imageProvider, fit: widget.fit,
            width: double.infinity, height: widget.fillH,
          ),
        );
      },
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF111111),
        height: 160,
        child: const Center(
          child: Text('تعذر تحميل هذه الصفحة',
              style: TextStyle(color: Color(0x59FFFFFF), fontSize: 12)),
        ),
      ),
    );
  }
}
