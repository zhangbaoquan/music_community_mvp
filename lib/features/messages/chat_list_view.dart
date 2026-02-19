import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/messages/message_controller.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';

import 'package:timeago/timeago.dart' as timeago;

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final MessageController controller = Get.put(MessageController());

    return Obx(() {
      if (controller.isLoading.value && controller.conversations.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.conversations.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('暂无私信消息', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.conversations.length,
        itemBuilder: (context, index) {
          final msg = controller.conversations[index];
          // Determine partner info
          // If I am sender, partner is receiver. If I am receiver, partner is sender.
          // But we don't effectively know "my id" easily without repeated fetching auth.currentUser.
          // However, controller.conversations logic ensured msg contains partner info if we assumed fetching logic logic was right.
          // Actually, in `MessageController` we stored the raw message.
          // We need to dynamically figure out who the "other person" is.
          // Let's rely on the controller logic being: `sender` is sender profile, `receiver` is receiver profile.
          // We just need to check which one is NOT me.

          // To be safe/clean, maybe we should have computed this in controller, but let's do it here.
          // We can get current user ID from Supabase instance in controller, or just pass it.
          // Let's assume the controller exposes "currentUserId" or we fetch it.
          // Better: Controller's `conversations` list could be a wrapper object `Conversation`?
          // For MVP, let's just cheat and check IDs.

          final myId = controller.supabaseCurrentUser?.id;
          if (myId == null) return const SizedBox();

          final isMeSender = msg.senderId == myId;
          final partnerId = isMeSender ? msg.receiverId : msg.senderId;
          final partnerName = isMeSender ? msg.receiverName : msg.senderName;
          final partnerAvatar = isMeSender
              ? msg.receiverAvatar
              : msg.senderAvatar;

          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundImage:
                      partnerAvatar != null && partnerAvatar.isNotEmpty
                      ? NetworkImage(partnerAvatar.toSecureUrl()!)
                      : null,
                  child: partnerAvatar == null || partnerAvatar.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                if (!isMeSender && !msg.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              partnerName ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              msg.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: (!isMeSender && !msg.isRead)
                    ? Colors.black87
                    : Colors.grey,
                fontWeight: (!isMeSender && !msg.isRead)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            trailing: Text(
              timeago.format(msg.createdAt, locale: 'zh'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              Get.toNamed(
                '/chat/$partnerId',
                parameters: {
                  'name': partnerName ?? 'Unknown',
                  'avatar': partnerAvatar ?? '',
                },
              );
            },
          );
        },
      );
    });
  }
}

// Extension to help access user ID easily if not in controller
extension ControllerExt on MessageController {
  // We need to add this property to controller potentially, or accessing Supabase instance directly
  // For now, let's assume we add a getter in controller.
  // Actually, let's just import Supabase here for ID check to be precise.
}
