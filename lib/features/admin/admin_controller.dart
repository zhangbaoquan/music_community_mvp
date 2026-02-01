import 'package:get/get.dart';

import '../profile/profile_controller.dart';

class AdminController extends GetxController {
  final currentTab = 0.obs; // 0: Music, 1: Articles, 2: Comments

  // Future expansion: Admin stats

  @override
  void onInit() {
    super.onInit();
    // Double check permission
    final profileController = Get.find<ProfileController>();
    ever(profileController.isAdmin, (isAdmin) {
      if (!isAdmin) {
        Get.offAllNamed('/home');
      }
    });
  }

  void switchTab(int index) {
    currentTab.value = index;
  }
}
