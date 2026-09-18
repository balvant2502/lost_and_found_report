import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../models/item_model.dart';

class LostFoundViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _itemsSubscription;
  List<ItemModel> _allItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _typeFilter = 'All'; // 'All', 'Lost', 'Found'
  String? _currentUniversity;

  List<ItemModel> get allItems => _allItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get typeFilter => _typeFilter;

  /// Initializes the real-time Firestore stream filtered by user's university
  void setUniversity(String university) {
    if (_currentUniversity == university && _itemsSubscription != null) return;
    _currentUniversity = university;
    _listenToUniversityItems(university);
  }

  void _listenToUniversityItems(String university) {
    _isLoading = true;
    notifyListeners();

    _itemsSubscription?.cancel();
    _itemsSubscription = _firestore
        .collection(AppConstants.collectionItems)
        .where('university', isEqualTo: university)
        .snapshots()
        .listen(
      (snapshot) {
        _allItems = snapshot.docs.map((doc) {
          return ItemModel.fromMap(doc.data(), doc.id);
        }).toList();

        // Sort by date descending
        _allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to items: $error');
        _errorMessage = 'Failed to load items: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Explore Feed items:
  /// - ONLY unresolved reports (isResolved == false)
  /// - Filtered by category
  /// - Filtered by type (Lost / Found / All)
  /// - Filtered by search query (item name or location)
  List<ItemModel> get exploreItems {
    return _allItems.where((item) {
      // 1. Only unresolved reports shown in Explore
      if (item.isResolved) return false;

      // 2. Type filter
      if (_typeFilter == 'Lost' && !item.isLost) return false;
      if (_typeFilter == 'Found' && item.isLost) return false;

      // 3. Category filter
      if (_selectedCategory != 'All' && item.category != _selectedCategory) {
        return false;
      }

      // 4. Search query (matches title or location)
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesLocation = item.location.toLowerCase().contains(query);
        final matchesDesc = item.description.toLowerCase().contains(query);
        if (!matchesTitle && !matchesLocation && !matchesDesc) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// User's personal reports (for personal dashboard, includes resolved & active)
  List<ItemModel> getUserReports(String uid) {
    return _allItems.where((item) => item.reportedBy == uid).toList();
  }

  // Dashboard Statistics
  int getUserTotalCount(String uid) => getUserReports(uid).length;
  int getUserActiveLostCount(String uid) =>
      getUserReports(uid).where((item) => item.isLost && !item.isResolved).length;
  int getUserActiveFoundCount(String uid) =>
      getUserReports(uid).where((item) => !item.isLost && !item.isResolved).length;
  int getUserResolvedCount(String uid) =>
      getUserReports(uid).where((item) => item.isResolved).length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  /// Creates a new lost or found report
  Future<bool> createReport({
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime date,
    required bool isLost,
    required String reportedBy,
    required String reporterName,
    required String university,
    double? latitude,
    double? longitude,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final docRef = _firestore.collection(AppConstants.collectionItems).doc();
      final newItem = ItemModel(
        id: docRef.id,
        title: title.trim(),
        description: description.trim(),
        category: category,
        location: location.trim(),
        latitude: latitude,
        longitude: longitude,
        date: date,
        isLost: isLost,
        reportedBy: reportedBy,
        reporterName: reporterName,
        university: university,
        isResolved: false,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await docRef.set(newItem.toMap());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create report: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark report as resolved or active (only reporter can do this)
  Future<bool> toggleResolveStatus({
    required String itemId,
    required bool currentResolved,
    required String currentUserId,
  }) async {
    final item = _allItems.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );

    // Permission check: only reporter can edit
    if (item.reportedBy != currentUserId) {
      _errorMessage = 'You can only edit your own reports.';
      notifyListeners();
      return false;
    }

    try {
      await _firestore
          .collection(AppConstants.collectionItems)
          .doc(itemId)
          .update({'isResolved': !currentResolved});
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update item status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete report (only reporter can do this)
  Future<bool> deleteReport({
    required String itemId,
    required String currentUserId,
  }) async {
    final item = _allItems.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );

    // Permission check: only reporter can delete
    if (item.reportedBy != currentUserId) {
      _errorMessage = 'You can only delete your own reports.';
      notifyListeners();
      return false;
    }

    try {
      await _firestore
          .collection(AppConstants.collectionItems)
          .doc(itemId)
          .delete();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete report: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
