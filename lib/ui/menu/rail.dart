import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:designdynamos/constant/data/main_menu_data.dart';

class Rail extends StatelessWidget {
  const Rail({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    var selectedIndex = 0;

    final destinations = <NavigationRailDestination>[];
    for (var i = 0; i < listMainMenu.length; i++) {
      final menu = listMainMenu[i];
      if (route?.settings.name == menu.route) {
        selectedIndex = i;
      }
      destinations.add(
        NavigationRailDestination(
          label: Text(menu.name),
          icon: Icon(menu.icon),
          selectedIcon: Icon(
            menu.icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isExtended = screenWidth >= 1200;

    return SingleChildScrollView(
      primary: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: IntrinsicHeight(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            color: Theme.of(context).colorScheme.surface,
            child: NavigationRail(
              extended: isExtended,
              minExtendedWidth: 240,
              selectedIndex: selectedIndex,
              labelType: isExtended ? null : NavigationRailLabelType.none,
              useIndicator: true,
              indicatorColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundColor: Colors.transparent,
              leading: InkWell(
                onTap: () => Get.toNamed("/"),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Icon(
                    Icons.add_to_drive,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              onDestinationSelected: (value) {
                Get.toNamed(listMainMenu[value].route);
              },
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
  }
}
