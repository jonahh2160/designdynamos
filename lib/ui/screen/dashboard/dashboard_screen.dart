import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:designdynamos/ui/screen/dashboard/dashboad_controller.dart';
import 'package:designdynamos/ui/widgets/card_announce_medium.dart';
import 'package:designdynamos/ui/widgets/headline.dart';
import 'package:designdynamos/ui/widgets/navigate_button.dart';
import 'package:designdynamos/ui/widgets/card_with_transparent_border.dart';
import 'package:designdynamos/ui/widgets/subtitle.dart';

class DailyTaskScreen extends GetResponsiveView<DashboardController> {
  DailyTaskScreen({super.key});

  @override
  Widget phone() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Headline(title: "Daily Tasks", caption: "Welcome to Tasqly"),
            const SizedBox(height: 32),
            SizedBox(
              height: 214,
              child: ListView.separated(
                itemCount: 12,
                shrinkWrap: true,
                primary: false,
                scrollDirection: Axis.horizontal,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 16),
                itemBuilder: (context, index) => const CardAnnounceMedium(
                  iconData: Icons.stars,
                  title: "Information",
                  subtitle: "Template",
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                const Subtitle(title: "Information"),
                const Spacer(),
                NavigateButton(
                  onTap: () {},
                  title: "More",
                  iconData: Icons.arrow_forward,
                ),
              ],
            ),
            SizedBox(
              height: 214,
              child: ListView.separated(
                itemCount: 10,
                shrinkWrap: true,
                primary: false,
                scrollDirection: Axis.horizontal,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 16),
                itemBuilder: (context, index) => CardWithTransparentAndBorder(
                  selected: index == 0,
                  title: 'Information',
                  description: 'Template',
                  onTap: () {},
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
