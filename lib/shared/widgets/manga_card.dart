import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/manga_model.dart';

// عرض الكارد 110px حتى يظهر 3 كاملة + نص رابعة
const double kCardW = 110.0;
const double kCardH = 158.0;

class MangaCard extends StatelessWidget {
  final MangaModel manga;
  final VoidCallback? onTap;

  const MangaCard({super.key, required this.manga, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textClr = isDark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);
    final subClr = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: kCardW,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CoverImage(manga: manga, isDark: isDark),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                manga.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textClr),
              ),
            ),
            const SizedBox(height: 3),
            _StarRow(rating: manga.rating),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final MangaModel manga;
  final bool isDark;
  const _CoverImage({required this.manga, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final neonGlow = isDark ? const Color(0x40BF5FFF) : const Color(0x305B5BD6);

    return Container(
      width: kCardW,
      height: kCardH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF161129),
        border: Border.all(color: isDark ? const Color(0x40BF5FFF) : const Color(0x305B5BD6), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4)),
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
                    placeholder: (_, __) => Container(color: const Color(0xFF161129)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF161129),
                      child: const Icon(Icons.broken_image_outlined, color: Colors.white24, size: 24),
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
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                    stops: const [0.0, 0.55],
                  ),
                ),
              ),
            ),

            // شارة التقييم
            Positioned(
              bottom: 7,
              left: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x59E8B85C)),
                ),
                child: Text(
                  '★ ${manga.rating.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.starColor, fontWeight: FontWeight.w800),
                ),
              ),
            ),

            // زر المفضلة
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x80BF5FFF), width: 1.5),
                  boxShadow: [BoxShadow(color: const Color(0x4DBF5FFF), blurRadius: 8)],
                ),
                child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final full = rating.round().clamp(0, 5);
    return Row(
      children: List.generate(5, (i) {
        final color = i < full
            ? AppColors.starColor
            : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15));
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(Icons.star_rounded, size: 10, color: color),
        );
      }),
    );
  }
}
