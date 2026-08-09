import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/manga_model.dart';
import '../../services/favorites_service.dart';

const double kCardW = 110.0;
const double kCardH = 158.0;

class MangaCard extends StatelessWidget {
  final MangaModel manga;
  final VoidCallback? onTap;

  const MangaCard({super.key, required this.manga, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: kCardW,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CoverImage(manga: manga),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                manga.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE2DEF0)),
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final clr = Color.lerp(const Color(0xFF1D1630), const Color(0xFF2A2040), _anim.value)!;
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
                  border: Border.all(color: const Color(0x20BF5FFF)),
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

class _CoverImage extends StatefulWidget {
  final MangaModel manga;
  const _CoverImage({required this.manga});

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  final _svc = FavoritesService.instance;

  @override
  void initState() {
    super.initState();
    _svc.load();
    _svc.addListener(_rebuild);
  }

  @override
  void dispose() {
    _svc.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  Future<void> _toggle() async {
    HapticFeedback.selectionClick();
    await _svc.toggle(widget.manga);
  }

  @override
  Widget build(BuildContext context) {
    final bool isFav  = _svc.isFavorite(widget.manga.id);
    final manga       = widget.manga;
    final hasImage    = manga.cover.isNotEmpty;

    return Container(
      width: kCardW, height: kCardH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF161129),
        border: Border.all(color: const Color(0x40BF5FFF), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4)),
          const BoxShadow(color: Color(0x40BF5FFF), blurRadius: 12),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'cover-${manga.id}',
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: manga.cover, fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(color: Color(0xFF161129)),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: Color(0xFF161129),
                        child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 24),
                      ),
                    )
                  : const ColoredBox(color: Color(0xFF161129)),
            ),

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

            Positioned(
              bottom: 7, left: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x59E8B85C)),
                ),
                child: Text('★ ${manga.rating.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.starColor, fontWeight: FontWeight.w800)),
              ),
            ),

            Positioned(
              top: 6, right: 6,
              child: GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFav
                          ? const Color(0xFFE63946).withOpacity(0.7)
                          : const Color(0xFFC084FC).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isFav ? [
                      BoxShadow(color: const Color(0xFFE63946).withOpacity(0.35), blurRadius: 8),
                    ] : null,
                  ),
                  child: Center(
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? const Color(0xFFE63946) : Colors.white,
                      size: 13,
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
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.round().clamp(0, 5);
    return Row(
      children: List.generate(5, (i) {
        final color = i < full
            ? AppColors.starColor
            : Colors.white.withOpacity(0.2);
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(Icons.star_rounded, size: 10, color: color),
        );
      }),
    );
  }
}
