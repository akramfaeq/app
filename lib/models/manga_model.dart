class MangaModel {
  final String id;
  final String title;
  final String cover;
  final double rating;
  final int    views;
  final int    chaptersCount;
  final String status;       // "مستمرة" | "مكتملة"
  final String type;         // "مانغا" | "مانهوا"
  final List<String> genres;
  final String? description;
  final bool   newChapter;
  final String? latestChapter;
  final DateTime? updatedAt;

  const MangaModel({
    required this.id,
    required this.title,
    required this.cover,
    required this.rating,
    required this.views,
    required this.chaptersCount,
    required this.status,
    required this.type,
    required this.genres,
    this.description,
    this.newChapter = false,
    this.latestChapter,
    this.updatedAt,
  });

  factory MangaModel.fromJson(Map<String, dynamic> json) {
    return MangaModel(
      id:            json['id']?.toString() ?? '',
      title:         json['title']?.toString() ?? '',
      cover:         json['cover']?.toString() ?? '',
      rating:        double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      views:         int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      chaptersCount: int.tryParse(json['chapters_count']?.toString() ??
                     json['chapters']?.toString() ?? '0') ?? 0,
      status:        json['status']?.toString() ?? 'مستمرة',
      type:          json['type']?.toString() ?? 'مانغا',
      genres:        (json['genres'] as List<dynamic>?)
                         ?.map((e) => e.toString())
                         .toList() ?? [],
      description:   json['description']?.toString(),
      newChapter:    json['new_chapter'] == true || json['new_chapter'] == 1,
      latestChapter: json['latest_chapter']?.toString(),
      updatedAt:     _parseDate(json['updated_at'] ?? json['last_updated']),
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    try { return DateTime.parse(val.toString()); } catch (_) { return null; }
  }

  /// تنسيق عدد المشاهدات (1.2K, 3.5M)
  String get formattedViews {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000)    return '${(views / 1000).toStringAsFixed(1)}K';
    return views > 0 ? views.toString() : '';
  }

  /// الحالة بالإنجليزي
  String get statusEn => status == 'مكتملة' ? 'Completed' : 'Ongoing';
}
