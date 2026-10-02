import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/campus_bounds.dart';
import '../../../core/utils/date_helper.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../models/item_model.dart';
import '../view_models/lost_found_view_model.dart';
import 'item_details_screen.dart';
import 'widgets/item_image_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _confirmDelete(BuildContext context, ItemModel item) {
    final authVM = context.read<AuthViewModel>();
    final lostFoundVM = context.read<LostFoundViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete Report?', style: TextStyle(fontWeight: FontWeight.w800)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Change University', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: isInitiallyCustom
                    ? 'Other University'
                    : selectedUni,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Campus'),
                items: AppConstants.defaultUniversities.map((uni) {
                  return DropdownMenuItem(
                    value: uni,
                    child: Text(
                      uni,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
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
                  CampusBounds.resolveRegion(universityName);
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF18181B),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => authVM.signOut(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF18181B)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.darkColor,
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Student',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _showEditUniversityDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_rounded,
                                  size: 12,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    user?.university ?? 'Select University',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF27272A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 11,
                                  color: Color(0xFF71717A),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Analytics Card (matching Screen 3 "Calorie stats / Analytics" from reference!)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analytics Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analytics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalCount Total Posts',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5EB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '${activeLost + activeFound} Active',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Sleek Stylized Vertical Bar Chart (matching reference)
                  SizedBox(
                    height: 72,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildChartBar(height: 26, isHighlighted: false),
                        _buildChartBar(height: 48, isHighlighted: false),
                        _buildChartBar(height: 32, isHighlighted: false),
                        _buildChartBar(height: 56, isHighlighted: false),
                        _buildChartBar(height: 40, isHighlighted: false),
                        _buildChartBar(height: 68, isHighlighted: true), // Coral Orange highlight bar!
                        _buildChartBar(height: 30, isHighlighted: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF4F4F5), height: 1),
                  const SizedBox(height: 14),

                  // Summary Metric Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Lost', activeLost.toString(), AppTheme.primaryColor),
                      _buildMetricItem('Found', activeFound.toString(), AppTheme.secondaryColor),
                      _buildMetricItem('Resolved', resolvedCount.toString(), const Color(0xFF71717A)),
                      _buildMetricItem('Total', totalCount.toString(), AppTheme.darkColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // My Reports Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Reports',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18181B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${myReports.length} items',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // My Reports List (matching "Challenge" list in reference)
            if (myReports.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 40,
                      color: Color(0xFFA1A1AA),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'You have not posted any reports yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF71717A),
                        fontWeight: FontWeight.w500,
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

  Widget _buildChartBar({required double height, required bool isHighlighted}) {
    return Container(
      width: 14,
      height: height,
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.primaryColor : const Color(0xFFE4E4E7),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFA1A1AA),
          ),
        ),
      ],
    );
  }

  Widget _buildMyReportTile(
    BuildContext context,
    ItemModel item,
    String currentUserId,
  ) {
    final lostFoundVM = context.read<LostFoundViewModel>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ItemImageView(
            imageUrl: item.imageUrl,
            width: 58,
            height: 58,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(14),
            placeholderBuilder: (_) => _placeholder(item),
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
                            ? const Color(0xFFFFF5EB)
                            : const Color(0xFFEDF7EE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isLost ? 'LOST' : 'FOUND',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: item.isLost
                              ? AppTheme.primaryColor
                              : AppTheme.secondaryColor,
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
                            ? const Color(0xFFF4F4F5)
                            : const Color(0xFFEDF7EE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isResolved ? 'RESOLVED' : 'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.isResolved
                              ? const Color(0xFF71717A)
                              : AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateHelper.formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
              ],
            ),
          ),

          // Quick Actions Popup
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF71717A)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }

  Widget _placeholder(ItemModel item) {
    return Container(
      color: const Color(0xFFF4F4F5),
      child: Center(
        child: Icon(
          Icons.category_rounded,
          size: 24,
          color: item.isLost ? AppTheme.primaryColor : AppTheme.secondaryColor,
        ),
      ),
    );
  }
}
