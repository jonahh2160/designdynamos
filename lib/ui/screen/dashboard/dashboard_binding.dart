import 'package:get/get.dart';
import 'package:designdynamos/ui/screen/dashboard/dashboad_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DashboardController());
  }
}
