import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../services/manga_service.dart';

class LibraryPage extends StatefulWidget {
  /// إذا true → مرتبة بالتقييم تنازلياً (قادمة من "عرض الكل" الأعلى تقييماً)
  final bool sortByRating;

  const LibraryPage({super.key, this.sortByRating = false});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _service = MangaService();
  List<MangaModel> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final list = await _service.fetchMangaList();
      if (!mounted) return;

      List<MangaModel> data;
      if (widget.sortByRating) {
        // مرتبة تنازلياً من الأعلى تقييماً
        data = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
      } else {
        // عشوائي
        data = [...list]..shuffle();
      }

      setState(() { _list = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = dark ? AppColors.darkBgDeep : AppColors.lightBgDeep;
    final accentClr = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final textClr = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Top Bar =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة گريد
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accentClr.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 14,
                      color: accentClr,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.t('libraryNav'),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: textClr,
                    ),
                  ),
                ],
              ),
            ),

            // ===== المحتوى =====
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: accentClr,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off_rounded,
                                  color: accentClr.withOpacity(0.5), size: 40),
                              const SizedBox(height: 12),
                              Text(
                                'خطأ، اسحب للتحديث',
                                style: TextStyle(
                                  color: dark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: accentClr,
                          child: GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              // نسبة الكارد: الصورة + النص تحتها
                              childAspectRatio: 110 / 210,
                            ),
                            itemCount: _list.length,
                            itemBuilder: (ctx, i) =>
                                _LibraryCard(manga: _list[i], dark: dark),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== كارد المكتبة =====
class _LibraryCard extends StatelessWidget {
  final MangaModel manga;
  final bool dark;

  const _LibraryCard({required this.manga, required this.dark});

  @override
  Widget build(BuildContext context) {
    final textClr = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);
    final subClr = dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderClr = dark
        ? const Color(0x40BF5FFF)
        : const Color(0x305B5BD6);
    final neonGlow = dark
        ? const Color(0x26BF5FFF)
        : const Color(0x205B5BD6);

    return GestureDetector(
      onTap: () {
        // TODO: افتح صفحة التفاصيل
        debugPrint('تفاصيل: ${manga.title}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== الصورة =====
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF161129),
                border: Border.all(color: borderClr, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(color: neonGlow, blurRadius: 12),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // الصورة
                    manga.cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: manga.cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFF161129),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF161129),
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white24,
                                size: 22,
                              ),
                            ),
                          )
                        : Container(color: const Color(0xFF161129)),

                    // تدرج سفلي
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55],
                          ),
                        ),
                      ),
                    ),

                    // شارة التقييم (أسفل يسار)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0x59E8B85C)),
                        ),
                        child: Text(
                          '★ ${manga.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.starColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    // زر المفضلة (أعلى يمين)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x80BF5FFF),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x4DBF5FFF),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // ===== العنوان =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              manga.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textClr,
              ),
            ),
          ),

          const SizedBox(height: 3),

          // ===== النجوم =====
          _StarRow(rating: manga.rating, dark: dark),

          const SizedBox(height: 2),

          // ===== الحالة =====
          Text(
            manga.status,
            style: TextStyle(fontSize: 10, color: subClr),
          ),
        ],
      ),
    );
  }
}

// ===== صف النجوم =====
class _StarRow extends StatelessWidget {
  final double rating;
  final bool dark;

  const _StarRow({required this.rating, required this.dark});

  @override
  Widget build(BuildContext context) {
    final full = rating.round().clamp(0, 5);
    return Row(
      children: List.generate(5, (i) {
        final color = i < full
            ? AppColors.starColor
            : (dark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.15));
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(Icons.star_rounded, size: 10, color: color),
        );
      }),
    );
  }
}
