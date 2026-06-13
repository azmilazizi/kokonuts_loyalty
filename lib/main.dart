import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/claim_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_shell.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/loyalty/coming_soon_screen.dart';
import 'services/auth_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await AuthService().init();
  runApp(const KokonutsLoyaltyApp());
}

final _router = GoRouter(
  initialLocation: '/home',
  refreshListenable: AuthService(),
  redirect: (context, state) {
    final loggedIn = AuthService().isLoggedIn;
    final loc = state.matchedLocation;

    if (loc.startsWith('/claim')) return null;

    final isAuthPath = loc == '/login' ||
        loc == '/register' ||
        loc.startsWith('/otp');

    if (!loggedIn && !isAuthPath) return '/login';
    if (loggedIn && isAuthPath) return '/home';

    return null;
  },
  routes: [
    GoRoute(
      path: '/claim/:token',
      builder: (context, state) =>
          ClaimScreen(token: state.pathParameters['token']!),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/loyalty/promotions',
            builder: (context, state) => const ComingSoonScreen(
              icon: Icons.local_offer_outlined,
              title: 'Promotions',
              description:
                  'Exclusive promotions and limited-time deals are coming your way. Stay tuned for exciting offers!',
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/loyalty/discounts',
            builder: (context, state) => const ComingSoonScreen(
              icon: Icons.discount_outlined,
              title: 'Discounts',
              description:
                  'Special member discounts are being crafted just for you. Check back soon for great savings!',
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/loyalty/rewards',
            builder: (context, state) => const ComingSoonScreen(
              icon: Icons.card_giftcard_outlined,
              title: 'Rewards',
              description:
                  'Amazing rewards are being prepared for our loyal members. Great things are on the way!',
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ]),
      ],
    ),
  ],
  errorBuilder: (context, state) => const LoginScreen(),
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
