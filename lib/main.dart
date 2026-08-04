import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_provider.dart';
import 'shared/widgets/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jbaeuagpdkqvigeygahw.supabase.co',
    publishableKey: 'sb_publishable_FHldfud15Bs-CSzFIoc-Jw_vEtz2Hmb',
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MangaNovaApp(),
    ),
  );
}

class MangaNovaApp extends StatelessWidget {
  const MangaNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: 'Manga Nova',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: provider.isLightTheme ? ThemeMode.light : ThemeMode.dark,
      home: const MainScaffold(),
    );
  }
}
