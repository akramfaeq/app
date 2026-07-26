import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_provider.dart';
import 'shared/widgets/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // شاشة كاملة بدون شريط الحالة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // اتجاه ثابت - portrait فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      theme:      buildLightTheme(),
      darkTheme:  buildDarkTheme(),
      themeMode:  provider.isLightTheme ? ThemeMode.light : ThemeMode.dark,

      // اتجاه التطبيق حسب اللغة
      builder: (context, child) {
        return Directionality(
          textDirection: provider.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },

      home: const MainScaffold(),
    );
  }
}
