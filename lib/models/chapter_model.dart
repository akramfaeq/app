import '../core/constants/app_constants.dart';

class ChapterModel {
  final int number;
  final int pages;
  final List<String> pageUrls;

  const ChapterModel({
    required this.number,
    required this.pages,
    required this.pageUrls,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    final rawPages = (json['pages'] as List<dynamic>?) ?? [];

    // كل صفحة هي Telegram file_id — نحولها لرابط عبر Cloudflare Worker
    final urls = rawPages
        .map((e) => AppConstants.pageUrl(e.toString()))
        .toList()
        .cast<String>();

    return ChapterModel(
      number:   int.tryParse(json['number']?.toString() ?? '0') ?? 0,
      pages:    urls.length,
      pageUrls: urls,
    );
  }
}
