import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/file_helper.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../chat/view_models/chat_view_model.dart';
import '../../chat/views/chat_screen.dart';
import '../models/item_model.dart';
import '../view_models/lost_found_view_model.dart';

class ItemDetailsScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case AppConstants.categoryElectronics:
        return Icons.devices_rounded;
      case AppConstants.categoryBooks:
        return Icons.menu_book_rounded;
      case AppConstants.categoryAccessories:
        return Icons.watch_rounded;
      case AppConstants.categoryIdCards:
        return Icons.badge_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _confirmDelete(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    final lostFoundVM = context.read<LostFoundViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text(
          'Are you sure you want to delete this report? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              final success = await lostFoundVM.deleteReport(
                itemId: item.id,
                currentUserId: authVM.currentUser?.uid ?? '',
              );
              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pop(); // Close details screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report deleted successfully.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lostFoundVM.errorMessage ?? 'Failed to delete report',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _startChat(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();
    final currentUser = authVM.currentUser;

    if (currentUser == null) return;

    final chatRoomId = await chatVM.getOrCreateChatRoom(
      itemId: item.id,
      itemTitle: item.title,
      currentUserId: currentUser.uid,
      currentUserName: currentUser.name,
      otherUserId: item.reportedBy,
      otherUserName: item.reporterName,
    );

    if (context.mounted && chatRoomId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: chatRoomId,
            itemTitle: item.title,
            otherUserName: item.reporterName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final lostFoundVM = context.watch<LostFoundViewModel>();
    final currentUserId = authVM.currentUser?.uid ?? '';
    final isReporter = item.reportedBy == currentUserId;
    final hasLocalImage = FileHelper.doesLocalImageExist(item.imageUrl);

    // Look up live state if available
    final liveItem = lostFoundVM.allItems.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          if (isReporter)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              tooltip: 'Delete Report',
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image or Large Icon Banner
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: liveItem.isLost
                      ? AppTheme.lostColor.withValues(alpha: 0.08)
                      : AppTheme.foundColor.withValues(alpha: 0.08),
                ),
                child: hasLocalImage
                    ? Image.file(
                        File(liveItem.imageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildLargePlaceholder(liveItem),
                      )
                    : _buildLargePlaceholder(liveItem),
              ),
            ),
            const SizedBox(height: 20),

            // Badges row: Lost/Found, Category, Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: liveItem.isLost
                        ? AppTheme.lostColor.withValues(alpha: 0.15)
                        : AppTheme.foundColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    liveItem.isLost ? 'LOST ITEM' : 'FOUND ITEM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: liveItem.isLost
                          ? AppTheme.lostColor
                          : AppTheme.foundColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    liveItem.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: liveItem.isResolved
                        ? AppTheme.resolvedColor.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    liveItem.isResolved ? 'RESOLVED' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: liveItem.isResolved
                          ? AppTheme.resolvedColor
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Item Title
            Text(
              liveItem.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            // Location & Date Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                liveItem.location,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date Occurred',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                DateHelper.formatDate(liveItem.date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Section
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                liveItem.description.isEmpty
                    ? 'No description provided.'
                    : liveItem.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Reported By Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            liveItem.reporterName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            liveItem.university,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isReporter)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            if (isReporter) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await lostFoundVM.toggleResolveStatus(
                    itemId: liveItem.id,
                    currentResolved: liveItem.isResolved,
                    currentUserId: currentUserId,
                  );
                },
                icon: Icon(
                  liveItem.isResolved
                      ? Icons.refresh_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(
                  liveItem.isResolved
                      ? 'Mark as Active'
                      : 'Mark as Resolved',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: liveItem.isResolved
                      ? AppTheme.primaryColor
                      : Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _startChat(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(
                  liveItem.isLost ? 'I Found This Item' : 'Claim / Inquire Item',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLargePlaceholder(ItemModel item) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(item.category),
            size: 64,
            color: item.isLost ? AppTheme.lostColor : AppTheme.foundColor,
          ),
          const SizedBox(height: 8),
          Text(
            item.category,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: item.isLost ? AppTheme.lostColor : AppTheme.foundColor,
            ),
          ),
        ],
      ),
    );
  }
}
