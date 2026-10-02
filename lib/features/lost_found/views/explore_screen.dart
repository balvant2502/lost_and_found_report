import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/date_helper.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../models/item_model.dart';
import '../view_models/lost_found_view_model.dart';
import 'item_details_screen.dart';
import 'widgets/item_image_view.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

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



  Color _getCardPastelBg(ItemModel item) {
    if (item.isFound) return const Color(0xFFEDF7EE); // soft mint green
    switch (item.category) {
      case AppConstants.categoryElectronics:
        return const Color(0xFFEFF6FF); // soft sky blue
      case AppConstants.categoryBooks:
        return const Color(0xFFFFF7ED); // soft peach
      case AppConstants.categoryAccessories:
        return const Color(0xFFF5F3FF); // soft lavender
      case AppConstants.categoryIdCards:
        return const Color(0xFFFEF9C3); // soft cream yellow
      default:
        return const Color(0xFFFFF4EC); // soft coral
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final lostFoundVM = context.watch<LostFoundViewModel>();
    final exploreItems = lostFoundVM.exploreItems;
    final university = authVM.currentUser?.university ?? 'Campus';

    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = screenWidth > 900
        ? 4
        : (isLandscape || screenWidth > 600 ? 3 : 2);
    final childAspectRatio = isLandscape ? 0.82 : 0.74;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            if (authVM.currentUser != null) {
              lostFoundVM.setUniversity(
                authVM.currentUser!.university,
              );
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Modern Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                      child: Row(
                        children: [
                          // Circular Left Icon Button
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.grid_view_rounded,
                                size: 20,
                                color: Color(0xFF18181B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Center University & Title Pill
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'CampusFound',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF18181B),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F4F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.school_rounded,
                                        size: 11,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          university,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF52525B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Circular View Toggle Button
                          GestureDetector(
                            onTap: () => setState(() => _isGridView = !_isGridView),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Center(
                                child: Icon(
                                  _isGridView
                                      ? Icons.view_agenda_outlined
                                      : Icons.grid_view_rounded,
                                  size: 20,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hero Dark Notification / Announcement Card (matching reference)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.darkColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Center(
                              child: Text(
                                '📍',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Campus Network',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Items pinned to your verified campus map.',
                                  style: TextStyle(
                                    color: Color(0xFFA1A1AA),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF71717A),
                            size: 18,
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => lostFoundVM.setSearchQuery(val),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            hintText: 'Search items or campus spots...',
                            hintStyle: const TextStyle(
                              color: Color(0xFFA1A1AA),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF71717A),
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      lostFoundVM.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lost / Found Type Switch Pills (matching reference date pills)
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
                            title: 'Lost Items',
                            selected: lostFoundVM.typeFilter == 'Lost',
                            activeColor: AppTheme.primaryColor,
                            onTap: () => lostFoundVM.setTypeFilter('Lost'),
                          ),
                          const SizedBox(width: 8),
                          _buildTypeSegment(
                            title: 'Found Items',
                            selected: lostFoundVM.typeFilter == 'Found',
                            activeColor: AppTheme.secondaryColor,
                            onTap: () => lostFoundVM.setTypeFilter('Found'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Category Horizontal Pills
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildCategoryPill('All', '✨', lostFoundVM),
                          ...AppConstants.categories.map(
                            (cat) => _buildCategoryPill(
                              cat,
                              _getCategoryEmoji(cat),
                              lostFoundVM,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Feed Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lostFoundVM.typeFilter == 'All'
                                ? 'Recent Reports'
                                : '${lostFoundVM.typeFilter} Reports',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF18181B),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${exploreItems.length} items',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // Items Feed
              if (lostFoundVM.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (exploreItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(lostFoundVM),
                )
              else if (_isGridView)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = exploreItems[index];
                        return _buildGridCard(context, item);
                      },
                      childCount: exploreItems.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = exploreItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildListCard(context, item),
                        );
                      },
                      childCount: exploreItems.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required String title,
    required bool selected,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = activeColor ?? AppTheme.darkColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : const Color(0xFFE5E7EB),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF52525B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(
    String category,
    String emoji,
    LostFoundViewModel vm,
  ) {
    final isSelected = vm.selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => vm.setCategoryFilter(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.darkColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.darkColor
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF27272A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern Grid Card (inspired directly by "Tuesday habit" cards in reference)
  Widget _buildGridCard(BuildContext context, ItemModel item) {
    final bgColor = _getCardPastelBg(item);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemDetailsScreen(item: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category tag + Status check badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_getCategoryEmoji(item.category)} ${item.category}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF27272A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: item.isFound
                        ? AppTheme.secondaryColor
                        : AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isFound
                        ? Icons.check_rounded
                        : Icons.priority_high_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Image or Stylized Placeholder
            Expanded(
              child: ItemImageView(
                imageUrl: item.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(16),
                placeholderBuilder: (_) => _buildGridPlaceholder(item),
              ),
            ),
            const SizedBox(height: 10),

            // Item Title
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF18181B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),

            // Location
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 12,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    item.location,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF71717A),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Relative Time
            Text(
              DateHelper.formatRelative(item.date),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern List Card (matching "Challenge" list in reference)
  Widget _buildListCard(BuildContext context, ItemModel item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemDetailsScreen(item: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ItemImageView(
              imageUrl: item.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(14),
              placeholderBuilder: (_) => _buildListPlaceholder(item),
            ),
            const SizedBox(width: 14),

            // Content
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
                          color: item.isFound
                              ? const Color(0xFFEDF7EE)
                              : const Color(0xFFFFF4EC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isLost ? 'LOST' : 'FOUND',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: item.isFound
                                ? AppTheme.secondaryColor
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF71717A),
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
                      color: Color(0xFF18181B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: Color(0xFF71717A),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF71717A),
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

            // Flame / Status Pill on right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.isLost ? '🔥 Lost' : '✅ Found',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.isLost
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateHelper.formatRelative(item.date),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridPlaceholder(ItemModel item) {
    return Container(
      color: Colors.white.withValues(alpha: 0.6),
      child: Center(
        child: Text(
          _getCategoryEmoji(item.category),
          style: const TextStyle(fontSize: 34),
        ),
      ),
    );
  }

  Widget _buildListPlaceholder(ItemModel item) {
    return Container(
      color: const Color(0xFFF4F4F5),
      child: Center(
        child: Text(
          _getCategoryEmoji(item.category),
          style: const TextStyle(fontSize: 24),
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
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F4F5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔍', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No active reports found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vm.searchQuery.isNotEmpty || vm.selectedCategory != 'All'
                  ? 'Try adjusting your search query or filters.'
                  : 'Be the first to report a lost or found item on campus!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
