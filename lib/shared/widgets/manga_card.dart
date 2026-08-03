import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/manga_model.dart';

const double kCardW = 110.0;
const double kCardH = 158.0;

class MangaCard extends StatelessWidget {
  final MangaModel manga;
  final VoidCallback? onTap;

  const MangaCard({super.key, required this.manga, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final textClr = isDark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);

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

class MangaCardSkeleton extends StatefulWidget {
  const MangaCardSkeleton({super.key});
  @override
  State<MangaCardSkeleton> createState() => _MangaCardSkeletonState();
}

class _MangaCardSkeletonState extends State<MangaCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clr1   = isDark ? const Color(0xFF1D1630) : const Color(0xFFE8E9F4);
    final clr2   = isDark ? const Color(0xFF2A2040) : const Color(0xFFF5F5FA);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final clr = Color.lerp(clr1, clr2, _anim.value)!;
        return SizedBox(
          width: kCardW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: kCardW, height: kCardH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: clr,
                  border: Border.all(
                    color: isDark ? const Color(0x20BF5FFF) : const Color(0x205B5BD6),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Container(height: 10, width: kCardW * 0.75,
                  decoration: BoxDecoration(color: clr, borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 5),
              Container(height: 8, width: kCardW * 0.45,
                  decoration: BoxDecoration(color: clr, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        );
      },
    );
  }
}

class _CoverImage extends StatelessWidget {
  final MangaModel manga;
  final bool isDark;
  const _CoverImage({required this.manga, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg      = isDark ? const Color(0xFF161129) : const Color(0xFFF5F5FA);
    final border      = isDark ? const Color(0x40BF5FFF) : const Color(0x403F5EFB);
    final neonGlow    = isDark ? const Color(0x40BF5FFF) : const Color(0x153F5EFB);
    final heartBorder = isDark ? const Color(0x80BF5FFF) : const Color(0x803F5EFB);
    final heartGlow   = isDark ? const Color(0x4DBF5FFF) : const Color(0x303F5EFB);
    final hasImage    = manga.cover.isNotEmpty;

    return Container(
      width: kCardW, height: kCardH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cardBg,
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.08), blurRadius: 15, offset: const Offset(0, 4)),
          BoxShadow(color: neonGlow, blurRadius: 12),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الصورة
            hasImage
                ? CachedNetworkImage(
                    imageUrl: manga.cover, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: cardBg),
                    errorWidget: (_, __, ___) => Container(
                      color: cardBg,
                      child: Icon(Icons.broken_image_outlined,
                          color: isDark ? Colors.white24 : const Color(0xFFBBBCE0), size: 24),
                    ),
                  )
                : Container(color: cardBg),

            // تدرج أسود فقط لما في صورة — بالنهاري بدون صورة لا تدرج
            if (hasImage)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                      stops: const [0.0, 0.55],
                    ),
                  ),
                ),
              ),

            // شارة التقييم — خلفية فاتحة بالنهاري لما ما في صورة
            Positioned(
              bottom: 7, left: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark || hasImage)
                      ? Colors.black.withOpacity(0.6)
                      : const Color(0xFFEAEBF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isDark || hasImage)
                        ? const Color(0x59E8B85C)
                        : const Color(0x40D97706),
                  ),
                ),
                child: Text(
                  '★ ${manga.rating.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.starColor : const Color(0xFFD97706),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // زر القلب
            Positioned(
              top: 7, right: 7,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  // النهاري: خلفية فاتحة شفافة بدل الأسود
                  color: isDark
                      ? Colors.black.withOpacity(0.55)
                      : Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: heartBorder, width: 1.5),
                  boxShadow: [BoxShadow(color: heartGlow, blurRadius: 8)],
                ),
                child: Icon(Icons.favorite_border_rounded,
                  // النهاري: أيقونة أزرق نيلي بدل أبيض
                  color: isDark ? Colors.white : const Color(0xFF3F5EFB),
                  size: 13),
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
    final full   = rating.round().clamp(0, 5);
    return Row(
      children: List.generate(5, (i) {
        final color = i < full
            ? (isDark ? AppColors.starColor : const Color(0xFFD97706))
            : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.12));
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(Icons.star_rounded, size: 10, color: color),
        );
      }),
    );
  }
}
