import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_community_mvp/data/models/private_message.dart';

class MessageController extends GetxController {
  final _supabase = Supabase.instance.client;

  // List of active conversations (represented by the latest message from each unique partner)
  final conversations = <PrivateMessage>[].obs;

  // Messages for the currently open chat
  final currentMessages = <PrivateMessage>[].obs;

  final isLoading = false.obs;
  final unreadCount = 0.obs;

  User? get supabaseCurrentUser => _supabase.auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    // Subscribe to realtime messages globally
    _setupRealtimeSubscription();
    fetchConversations();
  }

  // 1. Fetch 'Inbox' (List of recent conversations)
  // Since we don't have a 'conversations' table, we simulate it by fetching my messages
  // and grouping by partner client-side (or using a complex query, but client-side grouping is easier for MVP).
  Future<void> fetchConversations() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    isLoading.value = true;
    try {
      // Fetch user's message history (last 500 maybe?)
      // We want distinct partners.
      // Strategy: Fetch all messages involved with me, order by created_at desc.
      // Then traverse and pick the first occurrence of each partner.

      final res = await _supabase
          .from('messages')
          .select(
            '*, sender:profiles!sender_id(username, avatar_url), receiver:profiles!receiver_id(username, avatar_url)',
          )
          .or('sender_id.eq.$myId,receiver_id.eq.$myId')
          .order('created_at', ascending: false)
          .limit(100);

      final allMessages = (res as List)
          .map((e) => PrivateMessage.fromMap(e))
          .toList();

      final Map<String, PrivateMessage> distinctConversations = {};
      int unread = 0;

      for (var msg in allMessages) {
        // Determine the 'partner' ID
        final isMeSender = msg.senderId == myId;
        final partnerId = isMeSender ? msg.receiverId : msg.senderId;

        // Count unread (If I am receiver and not read)
        if (!isMeSender && !msg.isRead) {
          // Note: This naive unread count only counts from the fetched limit(100).
          // For accurate global unread, we need a separate count query properly.
          // But for MVP this is okay-ish for the reactive badge if lists are fresh.
          unread++;
        }

        if (!distinctConversations.containsKey(partnerId)) {
          distinctConversations[partnerId] = msg;
        }
      }

      conversations.value = distinctConversations.values.toList();

      // Better unread count (Server side count)
      final unreadRes = await _supabase
          .from('messages')
          .count()
          .eq('receiver_id', myId)
          .eq('is_read', false);
      unreadCount.value = unreadRes;
    } catch (e) {
      print('Fetch Conversations Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 2. Open a chat thread
  Future<void> fetchMessages(String partnerId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    isLoading.value = true;
    try {
      final res = await _supabase
          .from('messages')
          .select(
            '*, sender:profiles!sender_id(username, avatar_url), receiver:profiles!receiver_id(username, avatar_url)',
          )
          .or(
            'and(sender_id.eq.$myId,receiver_id.eq.$partnerId),and(sender_id.eq.$partnerId,receiver_id.eq.$myId)',
          )
          .order('created_at', ascending: true); // Oldest top, newest bottom

      currentMessages.value = (res as List)
          .map((e) => PrivateMessage.fromMap(e))
          .toList();

      // Mark as read immediately when opening
      _markAsRead(partnerId);
    } catch (e) {
      print('Fetch Messages Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 3. Send Message
  Future<void> sendMessage(String partnerId, String content) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null || content.trim().isEmpty) return;

    try {
      final newMsg = {
        'sender_id': myId,
        'receiver_id': partnerId,
        'content': content.trim(),
        'is_read': false,
      };

      // Optimistic/Local addition could be done, but let's rely on refresh or Realtime
      await _supabase.from('messages').insert(newMsg);

      // Refresh current thread if open
      // Actually fetchMessages adds it, or Realtime adds it.
      // Let's just manually append to be snappy
      // But we need the full object with profile...
      // For MVP, just refetch is safest to get timestamp etc.
      await fetchMessages(partnerId);
      // Also update inbox list order
      fetchConversations();
    } catch (e) {
      print('Send Message Error: $e');
      Get.snackbar('错误', '发送失败，请重试');
    }
  }

  Future<void> _markAsRead(String partnerId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', myId)
          .eq('sender_id', partnerId)
          .eq('is_read', false);

      // Update local unread count
      // Recalculate or simple decrement? Let's just refetch conversations to be safe sync.
      // fetchConversations(); // Might be too heavy, just adjust local state if needed.
      final unreadRes = await _supabase
          .from('messages')
          .count()
          .eq('receiver_id', myId)
          .eq('is_read', false);
      unreadCount.value = unreadRes;
    } catch (e) {
      print('Mark Read Error: $e');
    }
  }

  void _setupRealtimeSubscription() {
    // Listen to INSERTs on messages table
    // If receiver_id == me, show notification or update inbox
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    _supabase
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: myId,
          ),
          callback: (payload) {
            // New message for me!
            // 1. Update unread count
            unreadCount.value++;
            // 2. Refresh Inbox
            fetchConversations();
            // 3. If chat open with this sender, refresh thread
            // (We need to track current open partnerId, maybe add a variable for that)
            // if (currentPartnerId == payload.newRow['sender_id']) { ... }

            Get.snackbar(
              '新消息',
              '您收到了一条新私信',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 3),
            );
          },
        )
        .subscribe();
  }
}
