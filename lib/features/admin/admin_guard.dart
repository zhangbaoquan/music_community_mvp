import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../profile/profile_controller.dart';

class AdminGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Ensure ProfileController is initialized
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }

    final profileController = Get.find<ProfileController>();

    // Check if user is logged in AND is admin
    // Note: profile might be loading, this is a simple check.
    // Ideally we should wait for profile load, but for now we redirect to home if not sure.

    if (profileController.isAdmin.value == true) {
      return null;
    } else {
      // Redirect to Home if not admin
      return const RouteSettings(name: '/home');
    }
  }
}
