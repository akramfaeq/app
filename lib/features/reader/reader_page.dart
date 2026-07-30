import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/manga_model.dart';
import '../../models/chapter_model.dart';
import '../../services/manga_service.dart';

class ReaderPage extends StatefulWidget {
  final MangaModel manga;
  final ChapterModel chapter;
  final List<ChapterModel> allChapters;

  const ReaderPage({
    super.key,
    required this.manga,
    required this.chapter,
    required this.allChapters,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _scrollCtrl = ScrollController();
  bool _showUI = true;
  List<String> _pages = [];
  bool _loading = true;
  late ChapterModel _currentChapter;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _loadPages();
    _scrollCtrl.addListener(_onScroll);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadPages() async {
    setState(() { _loading = true; _pages = []; });
    try {
      final service = MangaService();
      final chapters = await service.fetchChapters(widget.manga.id);
      final chapter = chapters.firstWhere(
        (c) => c.number == _currentChapter.number,
        orElse: () => _currentChapter,
      );
      if (!mounted) return;
      setState(() {
        _pages = chapter.pageUrls;
        _loading = false;
      });
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
      setState(() => _currentPage = 1);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (_pages.isEmpty) return;
    final total = _scrollCtrl.position.maxScrollExtent;
    final current = _scrollCtrl.offset;
    if (total > 0) {
      final page = ((current / total) * _pages.length).ceil().clamp(1, _pages.length);
      if (page != _currentPage) setState(() => _currentPage = page);
    }
  }

  void _toggleUI() => setState(() => _showUI = !_showUI);

  ChapterModel? get _prevChapter {
    final sorted = [...widget.allChapters]..sort((a, b) => a.number.compareTo(b.number));
    final idx = sorted.indexWhere((c) => c.number == _currentChapter.number);
    return idx > 0 ? sorted[idx - 1] : null;
  }

  ChapterModel? get _nextChapter {
    final sorted = [...widget.allChapters]..sort((a, b) => a.number.compareTo(b.number));
    final idx = sorted.indexWhere((c) => c.number == _currentChapter.number);
    return idx < sorted.length - 1 ? sorted[idx + 1] : null;
  }

  void _goToChapter(ChapterModel chapter) {
    setState(() => _currentChapter = chapter);
    _loadPages();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== صفحات المانغا =====
          GestureDetector(
            onTap: _toggleUI,
            child: _loading
                ? Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2))
                : _pages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_outlined, color: Colors.white24, size: 52),
                            const SizedBox(height: 12),
                            const Text('لا توجد صفحات',
                                style: TextStyle(color: Colors.white38, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _pages.length,
                        itemBuilder: (ctx, i) => _PageImage(url: _pages[i]),
                      ),
          ),

          // ===== الهيدر =====
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _showUI ? 0 : -120,
            left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.manga.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('الفصل ${_currentChapter.number}',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== الفوتر =====
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _showUI ? 0 : -150,
            left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_pages.isNotEmpty) ...[
                    Text('$_currentPage / ${_pages.length}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7),
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _pages.isEmpty ? 0 : _currentPage / _pages.length,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _prevChapter != null ? () => _goToChapter(_prevChapter!) : null,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _prevChapter != null ? 1.0 : 0.3,
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(_prevChapter != null ? 'فصل ${_prevChapter!.number}' : 'لا يوجد',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _nextChapter != null ? () => _goToChapter(_nextChapter!) : null,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _nextChapter != null ? 1.0 : 0.3,
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: _nextChapter != null
                                    ? LinearGradient(colors: [accent.withOpacity(0.8), accent])
                                    : null,
                                color: _nextChapter == null ? Colors.white.withOpacity(0.1) : null,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _nextChapter != null
                                    ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 12)]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_nextChapter != null ? 'فصل ${_nextChapter!.number}' : 'لا يوجد',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageImage extends StatelessWidget {
  final String url;
  const _PageImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      placeholder: (_, __) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        color: const Color(0xFF0D0D0D),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6), strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        height: 200,
        color: const Color(0xFF0D0D0D),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 32),
        ),
      ),
    );
  }
}
