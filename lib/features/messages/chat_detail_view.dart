import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/messages/message_controller.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';

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
                  ? NetworkImage(widget.partnerAvatar!.toSecureUrl())
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
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

                      final profileCtrl = Get.isRegistered<ProfileController>()
                          ? Get.find<ProfileController>()
                          : Get.put(ProfileController());

                      // Determine if we should show time
                      bool showTime = false;
                      if (index == 0) {
                        showTime = true;
                      } else {
                        final lastMsg = controller.currentMessages[index - 1];
                        if (msg.createdAt
                                .difference(lastMsg.createdAt)
                                .inMinutes >
                            5) {
                          showTime = true;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Time Stamp (Outside the Row)
                          if (showTime)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  timeago.format(msg.createdAt, locale: 'zh'),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),

                          // 2. Message Row
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Avatar (Partner)
                                if (!isMe) ...[
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage:
                                        widget.partnerAvatar != null &&
                                            widget.partnerAvatar!.isNotEmpty
                                        ? NetworkImage(
                                            widget.partnerAvatar!.toSecureUrl(),
                                          )
                                        : null,
                                    child:
                                        widget.partnerAvatar == null ||
                                            widget.partnerAvatar!.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 20,
                                            color: Colors.white,
                                          )
                                        : null,
                                    backgroundColor: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // Content Column
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      // Name
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                          left: 4,
                                          right: 4,
                                        ),
                                        child: Obx(() {
                                          final myName =
                                              profileCtrl.username.value;
                                          // Always show name for consistency
                                          return Text(
                                            isMe
                                                ? (myName.isEmpty
                                                      ? '我'
                                                      : myName)
                                                : widget.partnerName,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          );
                                        }),
                                      ),

                                      // Bubble
                                      ChatBubble(
                                        clipper: ChatBubbleClipper1(
                                          type: isMe
                                              ? BubbleType.sendBubble
                                              : BubbleType.receiverBubble,
                                        ),
                                        alignment: isMe
                                            ? Alignment.topRight
                                            : Alignment.topLeft,
                                        margin: EdgeInsets.zero,
                                        backGroundColor: isMe
                                            ? Colors.blue
                                            : Colors.white,
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.65,
                                          ),
                                          child: Text(
                                            msg.content,
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.white
                                                  : Colors.black87,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right Avatar (Me)
                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  Obx(() {
                                    final myAvatar =
                                        profileCtrl.avatarUrl.value;
                                    return CircleAvatar(
                                      radius: 18,
                                      backgroundImage: myAvatar.isNotEmpty
                                          ? NetworkImage(myAvatar.toSecureUrl())
                                          : null,
                                      child: myAvatar.isEmpty
                                          ? const Icon(
                                              Icons.person,
                                              size: 20,
                                              color: Colors.white,
                                            )
                                          : null,
                                      backgroundColor: Colors.blue[300],
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),

              // Input Area
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
        ),
      ),
    );
  }
}
