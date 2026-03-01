import 'package:get/get.dart';
import '../data/services/log_service.dart';
import '../features/auth/auth_controller.dart';
import '../features/profile/profile_controller.dart';
import '../features/player/player_controller.dart';
import '../features/safety/safety_service.dart';
import '../features/content/article_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Services & Controllers that should be available globally
    Get.put(LogService(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(ProfileController(), permanent: true);
    Get.put(SafetyService(), permanent: true);
    Get.put(PlayerController(), permanent: true);
    Get.put(ArticleController(), permanent: true);
  }
}
