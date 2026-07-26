import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/manga_model.dart';
import '../../../shared/widgets/manga_card.dart';

/// سلايدر آخر الإصدارات مع الجدول الزمني (اليوم / الأمس / هذا الأسبوع / أقدم)
class TimelineSlider extends StatelessWidget {
  final Map<String, List<MangaModel>> groups; // {'today':[], 'yesterday':[], ...}
  final Map<String, String> labels;           // {'today':'اليوم', ...}
  final void Function(MangaModel)? onCardTap;

  const TimelineSlider({
    super.key,
    required this.groups,
    required this.labels,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    // دمج كل المجموعات بترتيب: اليوم ← الأمس ← الأسبوع ← أقدم
    // مع label فاصل بينهم
    final order = ['today', 'yesterday', 'week', 'older'];

    // نبني قائمة مدمجة: (label | manga)
    final List<_TimelineItem> items = [];
    for (final key in order) {
      final list = groups[key] ?? [];
      if (list.isEmpty) continue;
      items.add(_TimelineItem.label(labels[key] ?? key));
      for (final m in list) {
        items.add(_TimelineItem.manga(m));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: AppConstants.cardHeight + 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: AppConstants.sectionPadH,
          right: AppConstants.sectionPadH / 2,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isLabel) {
            return _TimelineLabel(label: item.label!);
          }
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: MangaCard(
              manga: item.manga!,
              onTap: () => onCardTap?.call(item.manga!),
            ),
          );
        },
      ),
    );
  }
}

/// الليبل الزمني (اليوم، الأمس...)
class _TimelineLabel extends StatelessWidget {
  final String label;
  const _TimelineLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentClr = isDark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentClr.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentClr.withOpacity(0.4)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accentClr,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // خط رأسي للتأثير البصري
          Container(
            width: 1.5,
            height: AppConstants.cardHeight - 30,
            color: accentClr.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}

// ===== Helper Model =====
class _TimelineItem {
  final bool isLabel;
  final String? label;
  final MangaModel? manga;

  _TimelineItem.label(this.label)
      : isLabel = true,
        manga   = null;

  _TimelineItem.manga(this.manga)
      : isLabel = false,
        label   = null;
}
