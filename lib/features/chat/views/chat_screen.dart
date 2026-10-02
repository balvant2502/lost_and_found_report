import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/date_helper.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../models/message_model.dart';
import '../view_models/chat_view_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String itemTitle;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.itemTitle,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().listenToMessages(widget.chatRoomId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authVM = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();
    final currentUser = authVM.currentUser;

    if (currentUser == null) return;

    _messageController.clear();
    final success = await chatVM.sendMessage(
      chatRoomId: widget.chatRoomId,
      text: text,
      senderId: currentUser.uid,
      senderName: currentUser.name,
    );

    if (success) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final chatVM = context.watch<ChatViewModel>();
    final currentUserId = authVM.currentUser?.uid ?? '';
    final messages = chatVM.currentMessages;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: isLandscape ? 48 : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.otherUserName,
              style: TextStyle(
                fontSize: isLandscape ? 15 : 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF18181B),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 11,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.itemTitle,
                    style: TextStyle(
                      fontSize: isLandscape ? 10 : 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF71717A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: chatVM.isLoadingMessages
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: isLandscape ? 8 : 16,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUserId;
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),

          // Message Input Field
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isLandscape ? 6 : 10,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: isLandscape ? 38 : null,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: isLandscape ? 38 : 44,
                    height: isLandscape ? 38 : 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.darkColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: _sendMessage,
                      icon: Icon(
                        Icons.send_rounded,
                        size: isLandscape ? 16 : 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.darkColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            if (!isMe) const SizedBox(height: 2),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isMe ? Colors.white : const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateHelper.formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.6)
                    : const Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: isLandscape ? 10 : 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isLandscape ? 48 : 64,
              height: isLandscape ? 48 : 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F4F5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('💬', style: TextStyle(fontSize: isLandscape ? 22 : 28)),
              ),
            ),
            SizedBox(height: isLandscape ? 8 : 12),
            Text(
              'Chat about ${widget.itemTitle}',
              style: TextStyle(
                fontSize: isLandscape ? 14 : 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF18181B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Coordinate item verification and campus handover safely.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isLandscape ? 11 : 13,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
