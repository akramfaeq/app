class AppConstants {
  static const String dataBaseUrl =
      'https://raw.githubusercontent.com/akramfaeq/manga/refs/heads/main/';

  static String mangaListUrl() =>
      '${dataBaseUrl}manga-list.json?t=${DateTime.now().millisecondsSinceEpoch}';

  static String chaptersUrl(String mangaId) =>
      '${dataBaseUrl}chapters-$mangaId.json?t=${DateTime.now().millisecondsSinceEpoch}';
}
