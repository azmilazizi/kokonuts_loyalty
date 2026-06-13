import 'package:flutter/material.dart';
import '../../theme.dart';

class ComingSoonScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? accentColor;

  const ComingSoonScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? kOrange;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 52, color: color),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: const Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: Color(0xFFF57C00),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_outlined,
                          size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      const Text(
                        'We\'re working hard to bring this to you',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
