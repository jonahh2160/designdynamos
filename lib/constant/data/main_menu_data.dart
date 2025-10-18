// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

class MainMenuData {
  String name;
  IconData? icon;
  Widget page;
  String route;
  String type_opening;

  MainMenuData({
    required this.name,
    this.icon,
    required this.page,
    required this.route,
    this.type_opening = "page",
  });
}

List<MainMenuData> listMainMenu = [
  MainMenuData(
    name: "Daily Tasks",
    page: Container(),
    icon: Icons.home_rounded,
    route: "/",
  ),
  MainMenuData(
    name: "Calendar",
    page: Container(),
    icon: Icons.calendar_month_rounded,
    route: "/calendar",
  ),
  MainMenuData(
    name: "Outlook",
    page: Container(),
    icon: Icons.explore_rounded,
    route: "/outlook",
  ),
  MainMenuData(
    name: "All Tasks",
    page: Container(),
    icon: Icons.assignment_turned_in_rounded,
    route: "/tasks",
  ),
  MainMenuData(
    name: "Goals",
    page: Container(),
    icon: Icons.track_changes_rounded,
    route: "/goals",
  ),
  MainMenuData(
    name: "Achievements",
    page: Container(),
    icon: Icons.workspace_premium_rounded, //or sub emoji_events_rounded
    route: "/achievements",
  ),
  MainMenuData(
    name: "Games",
    page: Container(),
    icon: Icons.videogame_asset_rounded,
    route: "/games",
  ),
];
