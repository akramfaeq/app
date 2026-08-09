import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../models/chapter_model.dart';
import '../../services/reading_progress_service.dart';

enum ReadingMode { vertical, horizontal }

class ReaderPage extends StatefulWidget {
  final MangaModel manga;
  final List<ChapterModel> allChapters;
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

  Timer? _readingTimer;
  int _secondsRead = 0;
  static const _minSeconds  = 9;
  static const _maxProgress = 0.95;

  static const _topbarColor = Color(0xBF0A0514);
  static const _dropBgColor = Color(0xF70E0814);
  static const _goldColor   = Color(0xFFE8B85C);
  static const _accent      = Color(0xFF9B5CF6);
  static const _textPrimary = Color(0xFFE2DEF0);
  static const _textSub     = Color(0x80FFFFFF);

  ChapterModel get _chapter => widget.allChapters[_chapterIdx];
  bool get _hasPrev => _chapterIdx > 0;
  bool get _hasNext => _chapterIdx < widget.allChapters.length - 1;

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

  void _startReadingTimer() {
    _secondsRead = 0;
    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsRead++;
      if (_secondsRead >= _minSeconds) _trySaveProgress();
    });
  }

  void _trySaveProgress() {
    if (_progress >= _maxProgress) return;
    final pages = _chapter.pageUrls;
    if (pages.isEmpty) return;
    final pageIdx = _currentPageIndex.clamp(0, pages.length - 1);
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

  void _goToChapter(int newIdx) {
    if (newIdx < 0 || newIdx >= widget.allChapters.length) return;
    setState(() {
      _chapterIdx       = newIdx;
      _progress         = 0.0;
      _currentPageIndex = 0;
      _chaptersDropOpen = false;
    });
    _startReadingTimer();
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t        = provider.t;
    final isAr     = provider.isArabic;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onTap,
        child: Stack(
          children: [
            _mode == ReadingMode.vertical
                ? _buildVertical(t)
                : _buildHorizontal(t, isAr),

            if (_chaptersDropOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _chaptersDropOpen = false),
                  child: Container(color: Colors.transparent),
                ),
              ),

            if (_chaptersDropOpen) _buildChaptersDropdown(t),

            _buildTopBar(isAr),

            _buildProgressBar(isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildVertical(String Function(String) t) {
    final pages = _chapter.pageUrls;
    if (pages.isEmpty) {
      return Center(child: Text(t('no_pages'), style: const TextStyle(color: _textSub, fontSize: 14)));
    }
    return ListView.builder(
      controller: _vertScrollCtrl,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 56, bottom: 60),
      itemCount: pages.length,
      itemBuilder: (ctx, i) => _PageImage(url: pages[i]),
    );
  }

  Widget _buildHorizontal(String Function(String) t, bool isAr) {
    final pages = _chapter.pageUrls;
    if (pages.isEmpty) {
      return Center(child: Text(t('no_pages_short'), style: const TextStyle(color: _textSub, fontSize: 14)));
    }
    final size = MediaQuery.of(context).size;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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

  Widget _buildTopBar(bool isAr) {
    final isHoriz = _mode == ReadingMode.horizontal;

    final Widget prevBtn = _NavBtn(
      icon: isAr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
      onTap: () => _goChapterDir('prev'),
      faded: !_hasPrev,
    );
    final Widget nextBtn = _NavBtn(
      icon: isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      onTap: () => _goChapterDir('next'),
      faded: !_hasNext,
    );

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
            decoration: BoxDecoration(
              color: _topbarColor,
              border: Border(bottom: BorderSide(color: _accent.withOpacity(0.15), width: 1)),
            ),
            child: Row(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              children: [
                prevBtn,
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
                        color: Colors.white, overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleMode,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHoriz ? _accent.withOpacity(0.22) : const Color(0x12FFFFFF),
                      border: Border.all(
                        color: isHoriz ? _accent.withOpacity(0.6) : const Color(0x26FFFFFF),
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
                nextBtn,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isAr) {
    final total   = _chapter.pageUrls.length;
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
            Text('$current / $total',
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: _goldColor, letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 10),
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
                    textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withOpacity(0.1),
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

  Widget _buildChaptersDropdown(String Function(String) t) {
    final sorted = widget.allChapters.reversed.toList();
    return Positioned(
      top: 56, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
            decoration: BoxDecoration(
              color: _dropBgColor,
              border: Border(bottom: BorderSide(color: _accent.withOpacity(0.25), width: 1)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              shrinkWrap: true,
              itemCount: sorted.length,
              itemBuilder: (ctx, i) {
                final ch        = sorted[i];
                final isCurrent = ch.number == _chapter.number;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final realIdx = widget.allChapters.indexWhere((c) => c.number == ch.number);
                    if (realIdx != -1) _goToChapter(realIdx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: isCurrent ? _accent.withOpacity(0.2) : const Color(0x08FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent ? _accent.withOpacity(0.45) : const Color(0x10FFFFFF),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${t('chapterWord')} ${ch.number}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? const Color(0xFFC9B6F5) : _textPrimary,
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            width: 7, height: 7,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent),
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

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool faded;

  const _NavBtn({required this.icon, required this.onTap, this.faded = false});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF9B5CF6);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: faded ? accent.withOpacity(0.3) : accent,
          boxShadow: faded ? null : [
            BoxShadow(color: accent.withOpacity(0.5), blurRadius: 12),
          ],
        ),
        child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ModeIcon extends StatelessWidget {
  const _ModeIcon();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(20, 20), painter: _ModeIconPainter());
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
    canvas.drawLine(Offset(cx, size.height * 0.79), Offset(cx, size.height * 0.21), paint);
    canvas.drawLine(Offset(cx - 5, size.height * 0.38), Offset(cx, size.height * 0.21), paint);
    canvas.drawLine(Offset(cx + 5, size.height * 0.38), Offset(cx, size.height * 0.21), paint);
    canvas.drawLine(Offset(cx - 5, size.height * 0.62), Offset(cx, size.height * 0.79), paint);
    canvas.drawLine(Offset(cx + 5, size.height * 0.62), Offset(cx, size.height * 0.79), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

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
    _blurCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _blurAnim = Tween<double>(begin: 6.0, end: 0.0).animate(
      CurvedAnimation(parent: _blurCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() { _blurCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppProvider>().t;

    return Container(
      color: Colors.black,
      child: CachedNetworkImage(
        imageUrl: widget.url,
        fit: widget.fit,
        width: double.infinity,
        height: widget.fillH,
        placeholder: (_, __) => Container(
          color: Colors.black,
          height: widget.fillH ?? 300,
          child: const Center(
            child: SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9B5CF6)),
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
          color: Colors.black,
          height: 160,
          child: Center(
            child: Text(t('page_load_error'),
                style: const TextStyle(color: Color(0x59FFFFFF), fontSize: 12)),
          ),
        ),
      ),
    );
  }
}
