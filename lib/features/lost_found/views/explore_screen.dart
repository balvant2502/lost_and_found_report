import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      final lostFoundVM = context.read<LostFoundViewModel>();
      if (authVM.currentUser != null) {
        lostFoundVM.setUniversity(authVM.currentUser!.university);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final lostFoundVM = context.watch<LostFoundViewModel>();
    final exploreItems = lostFoundVM.exploreItems;
    final university = authVM.currentUser?.university ?? 'Your University';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CampusFound',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            Row(
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    university,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
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
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_searching_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find it. Return it.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Search your campus community for a match.',
                        style: TextStyle(
                          color: Color(0xFFDCE7FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => lostFoundVM.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search by item name or location...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          lostFoundVM.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Lost / Found Type Switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTypeSegment(
                  title: 'All Items',
                  selected: lostFoundVM.typeFilter == 'All',
                  onTap: () => lostFoundVM.setTypeFilter('All'),
                ),
                const SizedBox(width: 8),
                _buildTypeSegment(
                  title: 'Lost Only',
                  selected: lostFoundVM.typeFilter == 'Lost',
                  badgeColor: AppTheme.lostColor,
                  onTap: () => lostFoundVM.setTypeFilter('Lost'),
                ),
                const SizedBox(width: 8),
                _buildTypeSegment(
                  title: 'Found Only',
                  selected: lostFoundVM.typeFilter == 'Found',
                  badgeColor: AppTheme.foundColor,
                  onTap: () => lostFoundVM.setTypeFilter('Found'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Category Chips Filter
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All', lostFoundVM),
                ...AppConstants.categories.map(
                  (cat) => _buildCategoryChip(cat, lostFoundVM),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Items Feed
          Expanded(
            child: lostFoundVM.isLoading
                ? const Center(child: CircularProgressIndicator())
                : exploreItems.isEmpty
                    ? _buildEmptyState(lostFoundVM)
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (authVM.currentUser != null) {
                            lostFoundVM.setUniversity(
                              authVM.currentUser!.university,
                            );
                          }
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: exploreItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = exploreItems[index];
                            return _buildItemCard(context, item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment({
    required String title,
    required bool selected,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (badgeColor ?? AppTheme.primaryColor)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? (badgeColor ?? AppTheme.primaryColor)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, LostFoundViewModel vm) {
    final isSelected = vm.selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (_) => vm.setCategoryFilter(category),
        avatar: category != 'All'
            ? Icon(
                _getCategoryIcon(category),
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              )
            : null,
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF334155),
        ),
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ItemModel item) {
    final hasLocalImage = !kIsWeb && FileHelper.doesLocalImageExist(item.imageUrl);
    final hasRemoteImage = (item.imageUrl?.startsWith('http') ?? false) ||
        (item.imageUrl?.startsWith('blob') ?? false);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemDetailsScreen(item: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail / Category Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: hasLocalImage
                      ? Image.file(
                          File(item.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPlaceholder(item),
                        )
                      : hasRemoteImage
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildPlaceholder(item),
                            )
                      : _buildPlaceholder(item),
                ),
              ),
              const SizedBox(width: 14),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge & Category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.isLost
                                ? AppTheme.lostColor.withValues(alpha: 0.12)
                                : AppTheme.foundColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.isLost ? 'LOST' : 'FOUND',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: item.isLost
                                  ? AppTheme.lostColor
                                  : AppTheme.foundColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Date & Reporter
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateHelper.formatDate(item.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholder(ItemModel item) {
    return Container(
      color: item.isLost
          ? AppTheme.lostColor.withValues(alpha: 0.08)
          : AppTheme.foundColor.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          _getCategoryIcon(item.category),
          size: 36,
          color: item.isLost ? AppTheme.lostColor : AppTheme.foundColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(LostFoundViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No active reports found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vm.searchQuery.isNotEmpty || vm.selectedCategory != 'All'
                  ? 'Try adjusting your search query or filters.'
                  : 'Be the first to report a lost or found item on campus!',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
