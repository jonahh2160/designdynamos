import 'package:flutter/material.dart';

class NavItemData {
  const NavItemData(this.icon, this.label, {this.badge, this.isActive = false});

  final IconData icon;
  final String label;
  final String? badge;
  final bool isActive;
}
