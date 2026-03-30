import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_notifier.dart';
import 'features/recipes/presentation/pages/recipe_list_page.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  final container = ProviderContainer();
  await container.read(authNotifierProvider.notifier).restoreFromStorage();
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'EasyBake',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8BB3D6),
        brightness: Brightness.light,
        typography: Typography.material2021(),
      ),
      home: const AppBootstrapPage(),
    );
  }
}

class AppBootstrapPage extends ConsumerStatefulWidget {
  const AppBootstrapPage({super.key});

  @override
  ConsumerState<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends ConsumerState<AppBootstrapPage>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 2400);
  static const _logoAsset = 'assets/app_logo.png';
  late final AnimationController _controller;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _controller.addListener(() {
      if (_controller.value > 0.001) {
        // Remove the native splash only when movement begins
        FlutterNativeSplash.remove();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await precacheImage(const AssetImage(_logoAsset), context);
      if (!mounted) {
        return;
      }
      _controller.forward();
    });

    Future<void>.delayed(_splashDuration, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(authNotifierProvider).isAuthenticated;

    if (_showSplash) {
      return _AnimatedSplash(animation: _controller, logoAsset: _logoAsset);
    }

    return isAuthenticated ? const RecipeListPage() : const LoginPage();
  }
}

class _AnimatedSplash extends StatelessWidget {
  const _AnimatedSplash({required this.animation, required this.logoAsset});

  final Animation<double> animation;
  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    final logoScale = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    );

    final logoOpacity = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    final textOpacity = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );

    final textSlide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6FAFF), Color(0xFFDDEBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: logoOpacity,
                child: ScaleTransition(
                  scale: logoScale,
                  child: Image.asset(
                    logoAsset,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: textOpacity,
                child: SlideTransition(
                  position: textSlide,
                  child: const Column(
                    children: [
                      Text(
                        'EasyBake',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Color(0xFF0F3559),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The brain behind your best meals.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF315C84),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
