import 'package:flutter/material.dart';

/// Shell pour le membre — bottom navigation
class MemberShell extends StatelessWidget {
  final Widget child;
  const MemberShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child; // À enrichir avec BottomNavigationBar
}

/// Shell pour l'admin — navigation latérale (drawer ou rail)
class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child; // À enrichir avec NavigationRail
}
