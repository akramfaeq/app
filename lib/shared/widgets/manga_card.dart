import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/manga_model.dart';

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
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CoverImage(manga: manga, isDark: isDark),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                manga.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textClr,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 3),
            _StarRow(rating: manga.rating),
            if (manga.formattedViews.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                manga.formattedViews,
                style: TextStyle(fontSize: 9, color: subClr),
              ),
            ],
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
    // glow بنفسجي مطابق للأصلي
    final neonGlow = isDark
        ? const Color(0x40BF5FFF)
        : const Color(0x305B5BD6);

    return GestureDetector(
      onTap: null,
      child: Container(
        width: 120,
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF161129),
          border: Border.all(
            color: isDark
                ? const Color(0x40BF5FFF)
                : const Color(0x305B5BD6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: neonGlow,
              blurRadius: 12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
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
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.white24, size: 28),
                      ),
                    )
                  : Container(color: const Color(0xFF161129)),

              // تدرج سفلي مطابق للأصلي
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

              // شارة التقييم - أسفل يسار
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0x59E8B85C),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '★ ${manga.rating.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.starColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // زر المفضلة - أعلى يمين (دائرة بنفسجية مطابقة للأصلي)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 30,
                  height: 30,
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
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
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
            : (isDark
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
