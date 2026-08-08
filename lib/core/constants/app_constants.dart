class AppConstants {
  static const _base = 'https://raw.githubusercontent.com/akramfaeq/manga/refs/heads/main/';
  static const _worker = 'https://manga-layer.akramfaeq523.workers.dev/?id=';

  static String mangaListUrl() =>
      '${_base}manga-list.json?t=${DateTime.now().millisecondsSinceEpoch}';

  static String chaptersUrl(String mangaId) =>
      '${_base}chapters-$mangaId.json?t=${DateTime.now().millisecondsSinceEpoch}';

  static String pageUrl(String fileId) =>
      '$_worker${Uri.encodeComponent(fileId)}';
}