import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/manga_model.dart';
import '../../../shared/widgets/manga_card.dart';

/// السلايدر الأفقي - يظهر 3 كاردات كاملة + نصف رابعة كتلميح
class MangaSlider extends StatelessWidget {
  final List<MangaModel> items;
  final void Function(MangaModel manga)? onCardTap;

  const MangaSlider({
    super.key,
    required this.items,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: AppConstants.cardHeight + 60, // الكارد + النص أسفله
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // snap للتمرير
        physics: const _SnapScrollPhysics(),
        padding: const EdgeInsets.only(
          left: AppConstants.sectionPadH,
          right: AppConstants.sectionPadH / 2,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: MangaCard(
              manga: items[index],
              onTap: () => onCardTap?.call(items[index]),
            ),
          );
        },
      ),
    );
  }
}

/// فيزياء التمرير مع snap بعرض الكارد
class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({super.parent});

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapScrollPhysics(parent: buildParent(ancestor));

  double _getPage(ScrollMetrics position) {
    final itemWidth = AppConstants.cardWidth + 10; // عرض الكارد + الفراغ
    return position.pixels / itemWidth;
  }

  double _getPixels(double page) {
    final itemWidth = AppConstants.cardWidth + 10;
    return page * itemWidth;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final page    = _getPage(position);
    final target  = velocity > 200
        ? page.ceil().toDouble()
        : velocity < -200
            ? page.floor().toDouble()
            : page.round().toDouble();

    if ((target - page).abs() < 0.01) return null;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      _getPixels(target),
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
