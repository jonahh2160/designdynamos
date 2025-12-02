import 'package:flutter/material.dart';
import 'package:designdynamos/constant/app_colors.dart';
import 'package:designdynamos/ui/menu/rail.dart';

class DesktopScaffold extends StatefulWidget {
  final Widget content;
  const DesktopScaffold({super.key, required this.content});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //! Menu
            const Rail(),
            //! Content
            Expanded(child: Stack(children: [widget.content])),
          ],
        ),
      ),
    );
  }
}
