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
    final pagesList = (json['pages'] as List<dynamic>?) ?? [];
    return ChapterModel(
      number:   int.tryParse(json['number']?.toString() ?? '0') ?? 0,
      pages:    pagesList.length,
      pageUrls: pagesList.map((e) => e.toString()).toList(),
    );
  }
}