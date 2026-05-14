import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'providers/favorites_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wallpaper_apply_provider.dart';
import 'providers/wallpaper_provider.dart';
import 'screens/splash_screen.dart';
import 'services/wallpaper_service.dart';
import 'services/wallpaper_api_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide the Android system navigation bar (and status bar) for an immersive
  // wallpaper-browsing experience. Swiping from edges still reveals them.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );

  final WallpaperApiService apiService = WallpaperApiService();
  final WallpaperService wallpaperService = WallpaperService();

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        Provider<WallpaperApiService>.value(value: apiService),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider()..loadTheme(),
        ),
        ChangeNotifierProvider<WallpaperProvider>(
          create: (_) => WallpaperProvider(apiService),
        ),
        ChangeNotifierProvider<WallpaperApplyProvider>(
          create: (_) => WallpaperApplyProvider(wallpaperService),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider()..loadFavorites(),
        ),
      ],
      child: const EidWallpapersApp(),
    ),
  );
}

class EidWallpapersApp extends StatelessWidget {
  const EidWallpapersApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stitch Wallpapers',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
