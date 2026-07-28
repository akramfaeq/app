class ChapterModel {
  final int number;
  final int pages;

  const ChapterModel({required this.number, required this.pages});

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    final pagesList = json['pages'] as List<dynamic>?;
    return ChapterModel(
      number: int.tryParse(json['number']?.toString() ?? '0') ?? 0,
      pages:  pagesList?.length ?? 0,
    );
  }
}
