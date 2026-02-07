import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActionSheetItem {
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final IconData? icon;

  ActionSheetItem({
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.icon,
  });
}

void showCustomActionSheet({
  required BuildContext context,
  required List<ActionSheetItem> actions,
  String? title,
}) {
  Get.bottomSheet(
    SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ...actions.map((action) {
              return InkWell(
                onTap: () {
                  Get.back(); // Close first
                  action.onTap();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: actions.indexOf(action) != actions.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (action.icon != null) ...[
                          Icon(
                            action.icon,
                            size: 18,
                            color: action.isDestructive
                                ? Colors.red
                                : Colors.black87,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          action.title,
                          style: TextStyle(
                            fontSize: 16,
                            color: action.isDestructive
                                ? Colors.red
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            // Divider
            Container(height: 8, color: Colors.grey[50]),
            // Cancel Button
            InkWell(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "取消",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
  );
}
