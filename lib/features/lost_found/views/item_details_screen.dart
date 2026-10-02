import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/date_helper.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../chat/view_models/chat_view_model.dart';
import '../../chat/views/chat_screen.dart';
import '../models/item_model.dart';
import '../view_models/lost_found_view_model.dart';
import 'widgets/item_image_view.dart';

class ItemDetailsScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

  String _getCategoryEmoji(String category) {
    switch (category) {
      case AppConstants.categoryElectronics:
        return '🎧';
      case AppConstants.categoryBooks:
        return '📚';
      case AppConstants.categoryAccessories:
        return '🎒';
      case AppConstants.categoryIdCards:
        return '🪪';
      default:
        return '📦';
    }
  }

  void _confirmDelete(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    final lostFoundVM = context.read<LostFoundViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete Report?', style: TextStyle(fontWeight: FontWeight.w800)),
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

  void _startChat(BuildContext context, ItemModel liveItem) async {
    final authVM = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();
    final currentUser = authVM.currentUser;

    if (currentUser == null) return;

    final chatRoomId = await chatVM.getOrCreateChatRoom(
      itemId: liveItem.id,
      itemTitle: liveItem.title,
      currentUserId: currentUser.uid,
      currentUserName: currentUser.name,
      otherUserId: liveItem.reportedBy,
      otherUserName: liveItem.reporterName,
    );

    if (context.mounted && chatRoomId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: chatRoomId,
            itemTitle: liveItem.title,
            otherUserName: liveItem.reporterName,
          ),
        ),
      );
    }
  }

  void _promptSecurityVerification(BuildContext context, ItemModel liveItem) {
    final answerController = TextEditingController();
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF7EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppTheme.secondaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Claim Verification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18181B),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The founder set a security question to verify legitimate ownership before you can claim this item.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF71717A), height: 1.3),
                ),
                const SizedBox(height: 14),

                // Question Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security Question',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        liveItem.securityQuestion!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Claimant Answer Input
                TextField(
                  controller: answerController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Your Answer',
                    hintText: 'Enter your answer to verify...',
                    errorText: localError,
                    prefixIcon: const Icon(Icons.key_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.darkColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final claimantAnswer = answerController.text.trim();
                if (claimantAnswer.isEmpty) {
                  setDialogState(() {
                    localError = 'Please enter an answer to proceed.';
                  });
                  return;
                }

                // Verify claimant answer against founder's secret verification
                if (!liveItem.verifySecurityAnswer(claimantAnswer)) {
                  setDialogState(() {
                    localError = 'Answer does not match founder\'s secret verification. Please try again.';
                  });
                  return;
                }

                Navigator.of(ctx).pop(); // Close dialog

                // Proceed to start chat with automated claim verification message
                if (context.mounted) {
                  await _startChatWithClaimAnswer(context, liveItem, claimantAnswer);
                }
              },
              child: const Text('Verify & Claim'),
            ),
          ],
        ),
      ),
    ).then((_) => answerController.dispose());
  }

  Future<void> _startChatWithClaimAnswer(
    BuildContext context,
    ItemModel liveItem,
    String claimantAnswer,
  ) async {
    final authVM = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();
    final currentUser = authVM.currentUser;

    if (currentUser == null) return;

    final chatRoomId = await chatVM.getOrCreateChatRoom(
      itemId: liveItem.id,
      itemTitle: liveItem.title,
      currentUserId: currentUser.uid,
      currentUserName: currentUser.name,
      otherUserId: liveItem.reportedBy,
      otherUserName: liveItem.reporterName,
    );

    if (context.mounted && chatRoomId != null) {
      // Send claim verification message
      final verificationMsg =
          '🔐 [Claim Verification] I answered your security question ("${liveItem.securityQuestion}") with: "$claimantAnswer"';
      await chatVM.sendMessage(
        chatRoomId: chatRoomId,
        text: verificationMsg,
        senderId: currentUser.uid,
        senderName: currentUser.name,
      );

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatRoomId: chatRoomId,
              itemTitle: liveItem.title,
              otherUserName: liveItem.reporterName,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final lostFoundVM = context.watch<LostFoundViewModel>();
    final currentUserId = authVM.currentUser?.uid ?? '';
    final isReporter = item.reportedBy == currentUserId;

    // Look up live state if available
    final liveItem = lostFoundVM.allItems.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Report Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF18181B),
          ),
        ),
        actions: [
          if (isReporter)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () => _confirmDelete(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image or Large Icon Banner
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: liveItem.isLost
                      ? const Color(0xFFFFF4EC)
                      : const Color(0xFFEDF7EE),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ItemImageView(
                  imageUrl: liveItem.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) =>
                      _buildLargePlaceholder(liveItem),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Badges row: Lost/Found, Category, Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: liveItem.isLost
                        ? const Color(0xFFFFF5EB)
                        : const Color(0xFFEDF7EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    liveItem.isLost ? '🔥 LOST ITEM' : '✅ FOUND ITEM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: liveItem.isLost
                          ? AppTheme.primaryColor
                          : AppTheme.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_getCategoryEmoji(liveItem.category)} ${liveItem.category}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: liveItem.isResolved
                        ? const Color(0xFFF4F4F5)
                        : const Color(0xFFEDF7EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    liveItem.isResolved ? 'RESOLVED' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: liveItem.isResolved
                          ? const Color(0xFF71717A)
                          : AppTheme.secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Item Title
            Text(
              liveItem.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF18181B),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),

            // Location & Date Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Campus Location',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF71717A),
                              ),
                            ),
                            Text(
                              liveItem.location,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (liveItem.hasCoordinates) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: FlutterMap(
                          key: ValueKey('detail_map_${liveItem.id}_${MediaQuery.of(context).orientation}'),
                          options: MapOptions(
                            initialCenter: LatLng(
                              liveItem.latitude!,
                              liveItem.longitude!,
                            ),
                            initialZoom: 16.5,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom |
                                  InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.campus_found',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    liveItem.latitude!,
                                    liveItem.longitude!,
                                  ),
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.topCenter,
                                  child: Icon(
                                    Icons.location_on,
                                    size: 34,
                                    color: liveItem.isLost
                                        ? AppTheme.primaryColor
                                        : AppTheme.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF4F4F5), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date Occurred',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF71717A),
                              ),
                            ),
                            Text(
                              DateHelper.formatDate(liveItem.date),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
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
            const SizedBox(height: 16),

            // Security Question Info Card (if item has one)
            if (liveItem.hasSecurityQuestion) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isReporter
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFEDF7EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isReporter
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFC7E5CA),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            size: 18,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isReporter
                              ? 'Security Question Active'
                              : 'Owner Verification Required',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Question: "${liveItem.securityQuestion}"',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    if (isReporter &&
                        liveItem.securityAnswer != null &&
                        liveItem.securityAnswer!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Secret Answer Key: ${liveItem.securityAnswer}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2D6A4F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (!isReporter) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'You must answer this security question correctly before claiming this item.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF2D6A4F)),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Description Section
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                liveItem.description.isEmpty
                    ? 'No description provided.'
                    : liveItem.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF3F3F46),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reported By Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.darkColor,
                    child: Text(
                      liveItem.reporterName.isNotEmpty
                          ? liveItem.reporterName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        Text(
                          liveItem.university,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isReporter)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Pill Buttons (matching reference "Get Started!")
            if (isReporter) ...[
              SizedBox(
                height: 54,
                child: FilledButton.icon(
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: liveItem.isResolved
                        ? AppTheme.darkColor
                        : AppTheme.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    if (!liveItem.isLost && liveItem.hasSecurityQuestion) {
                      _promptSecurityVerification(context, liveItem);
                    } else {
                      _startChat(context, liveItem);
                    }
                  },
                  icon: Icon(
                    (!liveItem.isLost && liveItem.hasSecurityQuestion)
                        ? Icons.lock_open_rounded
                        : Icons.chat_bubble_outline_rounded,
                  ),
                  label: Text(
                    liveItem.isLost
                        ? 'I Found This Item'
                        : (liveItem.hasSecurityQuestion
                            ? 'Answer Question & Claim'
                            : 'Claim / Inquire Item'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.darkColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
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
          Text(
            _getCategoryEmoji(item.category),
            style: const TextStyle(fontSize: 54),
          ),
          const SizedBox(height: 8),
          Text(
            item.category,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: item.isLost ? AppTheme.primaryColor : AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
