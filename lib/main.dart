import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/claim_screen.dart';
import 'theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const KokonutsLoyaltyApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/claim/:token',
      builder: (context, state) => ClaimScreen(
        token: state.pathParameters['token']!,
      ),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const _LandingPage(),
    ),
  ],
  errorBuilder: (context, state) => const _LandingPage(),
);

class KokonutsLoyaltyApp extends StatelessWidget {
  const KokonutsLoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kokonuts Loyalty',
      theme: buildAppTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _LandingPage extends StatelessWidget {
  const _LandingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_cafe_rounded, size: 64, color: kOrange),
            const SizedBox(height: 16),
            Text(
              'KOKONUTS',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: kOrange,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loyalty Programme',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
