import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/manga_model.dart';

class FavoriteItem {
  final String id;
  final String title;
  final String cover;
  final double rating;
  String? category;

  FavoriteItem({
    required this.id,
    required this.title,
    required this.cover,
    required this.rating,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'cover': cover,
    'rating': rating, 'category': category,
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> j) => FavoriteItem(
    id: j['id'], title: j['title'], cover: j['cover'],
    rating: (j['rating'] as num).toDouble(), category: j['category'],
  );

  MangaModel toManga() => MangaModel(
    id: id, title: title, cover: cover, rating: rating,
    views: 0, chaptersCount: 0, status: 'مستمرة',
    type: 'مانغا', genres: [],
  );
}

class FavoritesService {
  static List<FavoriteItem> _favs = [];
  static bool _loaded = false;

  static List<FavoriteItem> get favorites => List.unmodifiable(_favs);

  static bool isFavorite(String id) => _favs.any((f) => f.id == id);

  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('favorites_v2');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _favs = list.map((e) => FavoriteItem.fromJson(e)).toList();
    }
    _loaded = true;
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites_v2', jsonEncode(_favs.map((f) => f.toJson()).toList()));
  }

  static Future<void> toggle(MangaModel manga) async {
    await load();
    if (isFavorite(manga.id)) {
      _favs.removeWhere((f) => f.id == manga.id);
    } else {
      _favs.add(FavoriteItem(
        id: manga.id, title: manga.title,
        cover: manga.cover, rating: manga.rating,
      ));
    }
    await _save();
  }

  static Future<void> remove(String id) async {
    _favs.removeWhere((f) => f.id == id);
    await _save();
  }

  static Future<void> setCategory(String id, String? category) async {
    final idx = _favs.indexWhere((f) => f.id == id);
    if (idx != -1) {
      _favs[idx].category = category;
      await _save();
    }
  }
}
