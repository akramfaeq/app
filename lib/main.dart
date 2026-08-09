import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_provider.dart';
import 'services/favorites_service.dart';
import 'features/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jbaeuagpdkqvigeygahw.supabase.co',
    publishableKey: 'sb_publishable_FHldfud15Bs-CSzFIoc-Jw_vEtz2Hmb',
  );

  await FavoritesService.instance.load();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider.value(value: FavoritesService.instance),
      ],
      child: const MangaNovaApp(),
    ),
  );
}

class MangaNovaApp extends StatelessWidget {
  const MangaNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>(); // للاستماع لتغيير اللغة
    return MaterialApp(
      title: 'Manga Nova',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      home: const SplashPage(),
    );
  }
}
