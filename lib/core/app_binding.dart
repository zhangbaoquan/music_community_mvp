import 'package:get/get.dart';
import '../data/services/log_service.dart';
import '../features/auth/auth_controller.dart';
import '../features/profile/profile_controller.dart';
import '../features/player/player_controller.dart';
import '../features/safety/safety_service.dart';
import '../features/content/article_controller.dart';

/// 全局依赖注入绑定
///
/// 将 Controller 分为关键路径（立即注册）和非关键路径（延迟加载），
/// 减少首屏渲染前的同步初始化开销。
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // === 关键路径：立即注册（首屏渲染前必须就绪） ===
    Get.put(LogService(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(SafetyService(), permanent: true);

    // === 非关键路径：延迟加载（首次 Get.find() 时才创建） ===
    // fenix: true 确保 Controller 被销毁后可重建
    Get.lazyPut(() => PlayerController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
    Get.lazyPut(() => ArticleController(), fenix: true);
  }
}
