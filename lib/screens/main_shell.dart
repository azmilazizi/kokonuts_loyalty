import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: kOrangeBg,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: kOrange),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer, color: kOrange),
            label: 'Promos',
          ),
          NavigationDestination(
            icon: Icon(Icons.discount_outlined),
            selectedIcon: Icon(Icons.discount, color: kOrange),
            label: 'Discounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard, color: kOrange),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: kOrange),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
