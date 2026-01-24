import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/messages/message_controller.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_chat_bubble/chat_bubble.dart';

class ChatDetailView extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? partnerAvatar;

  const ChatDetailView({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
  });

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final MessageController controller = Get.find<MessageController>();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch messages for this partner
    controller.fetchMessages(widget.partnerId);
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 100, // Extra for padding
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_msgCtrl.text.trim().isEmpty) return;
    controller.sendMessage(widget.partnerId, _msgCtrl.text);
    _msgCtrl.clear();
    // Scroll to bottom after a slight delay for UI update
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    // Need current user ID to distinguish self vs other bubbles
    final myId = controller.supabaseCurrentUser?.id;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  widget.partnerAvatar != null &&
                      widget.partnerAvatar!.isNotEmpty
                  ? NetworkImage(widget.partnerAvatar!)
                  : null,
              child:
                  widget.partnerAvatar == null || widget.partnerAvatar!.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.partnerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black),
      ),
      body: Column(
        children: [
          // Msg List
          Expanded(
            child: Obx(() {
              // Wait for initial load if empty? Or just show empty.
              // Note: currentMessages is reactive.

              // We should listen to list changes to auto-scroll,
              // but doing it in build() is messy.
              // Usually handled by ever() worker in controller or key update.
              // For MVP manual scroll on send is OK.

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: controller.currentMessages.length,
                itemBuilder: (context, index) {
                  final msg = controller.currentMessages[index];
                  final isMe = msg.senderId == myId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Time (Optional: show periodically)
                        if (index == 0 ||
                            msg.createdAt
                                    .difference(
                                      controller
                                          .currentMessages[index - 1]
                                          .createdAt,
                                    )
                                    .inMinutes >
                                5)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                timeago.format(msg.createdAt, locale: 'zh'),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),

                        ChatBubble(
                          clipper: ChatBubbleClipper1(
                            type: isMe
                                ? BubbleType.sendBubble
                                : BubbleType.receiverBubble,
                          ),
                          alignment: isMe
                              ? Alignment.topRight
                              : Alignment.topLeft,
                          margin: const EdgeInsets.only(top: 4),
                          backGroundColor: isMe ? Colors.blue : Colors.white,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Text(
                              msg.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: '发送消息...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
