import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:designdynamos/ui/responive/responsive_layout.dart';
import 'package:designdynamos/ui/screen/dashboard/dashboard_binding.dart';
import 'package:designdynamos/ui/screen/dashboard/dashboard_screen.dart';

class AppPages {
  AppPages._();

  static final routes = [
    GetPage(
      name: "/",
      page: () => ResponsiveLayout(content: DailyTaskScreen()),
      bindings: [
        DashboardBinding(),
      ],
    ),
    GetPage(
      name: "/calendar",
      page: () => const ResponsiveLayout(
        content: Align(
          alignment: Alignment.center,
          child: Text("calendar"),
        ),
      ),
    ),
    GetPage(
      name: "/outlook",
      page: () => const ResponsiveLayout(
        content: Align(
          alignment: Alignment.center,
          child: Text("outlook"),
        ),
      ),
    ),
    GetPage(
      name: "/tasks",
      page: () => const ResponsiveLayout(
        content: Align(
          alignment: Alignment.center,
          child: Text("tasks"),
        ),
      ),
    ),
    GetPage(
      name: "/vente",
      page: () => const ResponsiveLayout(
        content: Align(
          alignment: Alignment.center,
          child: Text("vente"),
        ),
      ),
    ),
    GetPage(
      name: "/goals",
      page: () => const ResponsiveLayout(
        content: Align(
          alignment: Alignment.center,
          child: Text("goals"),
        ),
      ),
    ),
    GetPage(
      name: "/achievements",
      page: () => const ResponsiveLayout(
        content: Align(
          alignment: Alignment.center,
          child: Text("achievements"),
        ),
      ),
    ),
    GetPage(
      name: "/games",
      page: () => const ResponsiveLayout(
        content: Align(
          alignment: Alignment.center,
          child: Text("games"),
        ),
      ),
    ),

    // GetPage(
    //   name: "/",
    //   page: () => DashboardPage(),
    //   bindings: [
    //     OverviewBinding(),
    //   ],
    // ),
  ];
}
