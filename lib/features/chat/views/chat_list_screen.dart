import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/date_helper.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../models/chat_room_model.dart';
import '../view_models/chat_view_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      final chatVM = context.read<ChatViewModel>();
      if (authVM.currentUser != null) {
        chatVM.initUserChats(authVM.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final chatVM = context.watch<ChatViewModel>();
    final currentUserId = authVM.currentUser?.uid ?? '';
    final rooms = chatVM.chatRooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: chatVM.isLoadingRooms
          ? const Center(child: CircularProgressIndicator())
          : rooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    if (authVM.currentUser != null) {
                      chatVM.initUserChats(authVM.currentUser!.uid);
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: rooms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return _buildChatRoomTile(context, room, currentUserId);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatRoomTile(
    BuildContext context,
    ChatRoomModel room,
    String currentUserId,
  ) {
    final otherName = room.getOtherParticipantName(currentUserId);
    final timeStr = room.lastMessageTime != null
        ? DateHelper.formatRelative(room.lastMessageTime!)
        : '';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: Text(
            otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                otherName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (timeStr.isNotEmpty)
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Re: ${room.itemTitle}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              room.lastMessage.isNotEmpty
                  ? room.lastMessage
                  : 'No messages yet',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatRoomId: room.id,
                itemTitle: room.itemTitle,
                otherUserName: otherName,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 44,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No active conversations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'When you inquire about a lost or found item, your conversations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
