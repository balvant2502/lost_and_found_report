import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/file_helper.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../models/item_model.dart';
import '../view_models/lost_found_view_model.dart';
import 'item_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _confirmDelete(BuildContext context, ItemModel item) {
    final authVM = context.read<AuthViewModel>();
    final lostFoundVM = context.read<LostFoundViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await lostFoundVM.deleteReport(
                itemId: item.id,
                currentUserId: authVM.currentUser?.uid ?? '',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Report deleted successfully'
                          : (lostFoundVM.errorMessage ?? 'Failed to delete report'),
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditUniversityDialog(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    final lostFoundVM = context.read<LostFoundViewModel>();
    String selectedUni =
        authVM.currentUser?.university ?? AppConstants.defaultUniversities.first;
    final isInitiallyCustom =
        !AppConstants.defaultUniversities.contains(selectedUni);
    bool isCustomUniversity = isInitiallyCustom;
    final customUniversityController = TextEditingController(
      text: isInitiallyCustom ? selectedUni : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Change University'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: isInitiallyCustom
                    ? 'Other University'
                    : selectedUni,
                decoration: const InputDecoration(labelText: 'Select Campus'),
                items: AppConstants.defaultUniversities.map((uni) {
                  return DropdownMenuItem(value: uni, child: Text(uni));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() {
                      selectedUni = val;
                      isCustomUniversity = val == 'Other University';
                      if (!isCustomUniversity) {
                        customUniversityController.clear();
                      }
                    });
                  }
                },
              ),
              if (isCustomUniversity) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: customUniversityController,
                  autofocus: !isInitiallyCustom,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Specific university name',
                    hintText: 'e.g. University of Toronto',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final universityName = isCustomUniversity
                    ? customUniversityController.text.trim()
                    : selectedUni;
                if (universityName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your specific university name.'),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                final success = await authVM.updateUniversity(universityName);
                if (success) {
                  lostFoundVM.setUniversity(universityName);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        authVM.errorMessage ?? 'Could not update university.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) => customUniversityController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final lostFoundVM = context.watch<LostFoundViewModel>();
    final user = authVM.currentUser;
    final uid = user?.uid ?? '';

    final myReports = lostFoundVM.getUserReports(uid);
    final totalCount = lostFoundVM.getUserTotalCount(uid);
    final activeLost = lostFoundVM.getUserActiveLostCount(uid);
    final activeFound = lostFoundVM.getUserActiveFoundCount(uid);
    final resolvedCount = lostFoundVM.getUserResolvedCount(uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => authVM.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Profile Card
            Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFFF0F7FF),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        (user?.name.isNotEmpty ?? false)
                            ? user!.name[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Student',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _showEditUniversityDialog(context),
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_rounded,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    user?.university ?? 'Select University',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Section
            const Text(
              'Report Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard(
                  title: 'Total Reports',
                  value: totalCount.toString(),
                  icon: Icons.assignment_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  title: 'Resolved',
                  value: resolvedCount.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green.shade700,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard(
                  title: 'Active Lost',
                  value: activeLost.toString(),
                  icon: Icons.help_outline_rounded,
                  color: AppTheme.lostColor,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  title: 'Active Found',
                  value: activeFound.toString(),
                  icon: Icons.inventory_2_outlined,
                  color: AppTheme.foundColor,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // My Reports Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${myReports.length} items',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // My Reports List
            if (myReports.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 44,
                      color: Color(0xFF94A3B8),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'You have not posted any reports yet.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myReports.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = myReports[index];
                  return _buildMyReportTile(context, item, uid);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyReportTile(
    BuildContext context,
    ItemModel item,
    String currentUserId,
  ) {
    final lostFoundVM = context.read<LostFoundViewModel>();
    final hasLocalImage = FileHelper.doesLocalImageExist(item.imageUrl);
    final hasRemoteImage = item.imageUrl?.startsWith('http') ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 60,
                child: hasLocalImage
                    ? Image.file(
                        File(item.imageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(item),
                      )
                    : hasRemoteImage
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(item),
                          )
                    : _placeholder(item),
              ),
            ),
            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.isLost
                              ? AppTheme.lostColor.withValues(alpha: 0.12)
                              : AppTheme.foundColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isLost ? 'LOST' : 'FOUND',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: item.isLost
                                ? AppTheme.lostColor
                                : AppTheme.foundColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.isResolved
                              ? AppTheme.resolvedColor.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isResolved ? 'RESOLVED' : 'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: item.isResolved
                                ? AppTheme.resolvedColor
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateHelper.formatDate(item.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions: Toggle Resolved & Delete
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
              onSelected: (action) async {
                if (action == 'view') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItemDetailsScreen(item: item),
                    ),
                  );
                } else if (action == 'toggle') {
                  await lostFoundVM.toggleResolveStatus(
                    itemId: item.id,
                    currentResolved: item.isResolved,
                    currentUserId: currentUserId,
                  );
                } else if (action == 'delete') {
                  _confirmDelete(context, item);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        item.isResolved
                            ? Icons.refresh_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        item.isResolved ? 'Mark as Active' : 'Mark as Resolved',
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Delete Report',
                          style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ItemModel item) {
    return Container(
      color: item.isLost
          ? AppTheme.lostColor.withValues(alpha: 0.08)
          : AppTheme.foundColor.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.category_rounded,
          size: 24,
          color: item.isLost ? AppTheme.lostColor : AppTheme.foundColor,
        ),
      ),
    );
  }
}
