import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/file_helper.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/lost_found_view_model.dart';
import 'widgets/campus_map_picker.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key, this.onSubmitted});

  final VoidCallback? onSubmitted;

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _roomDetailController = TextEditingController();

  bool _isLost = true; // true = lost, false = found
  String _selectedCategory = AppConstants.categories.first;
  DateTime _selectedDate = DateTime.now();
  String? _selectedImagePath;
  bool _isSavingImage = false;

  LatLng? _pinnedLocation;
  String _resolvedLocationName = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _roomDetailController.dispose();
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

  void _pickImage(ImageSource source) async {
    setState(() => _isSavingImage = true);

    final result = await FileHelper.pickAndSaveReportImage(source: source);

    setState(() => _isSavingImage = false);

    if (result.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else if (result.isSuccess) {
      setState(() {
        _selectedImagePath = result.filePath;
      });
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Item Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Max image size is 10 MB. Saved locally on device.',
                style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF18181B)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF18181B)),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pinnedLocation == null || _resolvedLocationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pinpoint the item location on the campus map.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final lostFoundVM = context.read<LostFoundViewModel>();
    final user = authVM.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a report.')),
      );
      return;
    }

    final roomNote = _roomDetailController.text.trim();
    final finalLocation = roomNote.isNotEmpty
        ? '$_resolvedLocationName ($roomNote)'
        : _resolvedLocationName;

    String? uploadedImageUrl;
    if (_selectedImagePath != null &&
        (kIsWeb || FileHelper.doesLocalImageExist(_selectedImagePath))) {
      try {
        uploadedImageUrl =
            await CloudinaryService.uploadImage(_selectedImagePath!);
      } catch (e) {
        debugPrint('Cloudinary upload skipped or failed: $e');
        uploadedImageUrl = _selectedImagePath;
      }
    }

    final success = await lostFoundVM.createReport(
      title: _titleController.text,
      description: _descController.text,
      category: _selectedCategory,
      location: finalLocation,
      latitude: _pinnedLocation!.latitude,
      longitude: _pinnedLocation!.longitude,
      date: _selectedDate,
      imageUrl: uploadedImageUrl,
      isLost: _isLost,
      reportedBy: user.uid,
      reporterName: user.name,
      university: user.university,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLost
                  ? 'Lost report published! Pinned inside ${user.university}.'
                  : 'Found report published! Pinned inside ${user.university}.',
            ),
            backgroundColor: AppTheme.foundColor,
          ),
        );
        _titleController.clear();
        _descController.clear();
        _roomDetailController.clear();
        setState(() {
          _selectedImagePath = null;
          _pinnedLocation = null;
          _resolvedLocationName = '';
        });
        widget.onSubmitted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lostFoundVM.errorMessage ?? 'Failed to submit report.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final lostFoundVM = context.watch<LostFoundViewModel>();
    final university = authVM.currentUser?.university ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Create Report',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF18181B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Report Type Selector (matching reference pills)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLost = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLost ? AppTheme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: _isLost
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '🔥 I Lost an Item',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _isLost ? Colors.white : const Color(0xFF52525B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLost = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLost ? AppTheme.secondaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: !_isLost
                                ? [
                                    BoxShadow(
                                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '✅ I Found an Item',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: !_isLost ? Colors.white : const Color(0xFF52525B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Item Title',
                  hintText: 'e.g. Silver MacBook Air or Blue Water Bottle',
                  prefixIcon: Icon(Icons.title_rounded, color: Color(0xFF71717A)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Grid (matching Screen 1 "Choose habit" from reference!)
              const Text(
                'Choose category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select the category that best matches your item',
                style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final width = (MediaQuery.of(context).size.width - 56) / 2;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: width > 130 ? width : 150,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFF5EB)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFF4F4F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _getCategoryEmoji(cat),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : const Color(0xFF27272A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // University Region Pinpoint Map
              const Row(
                children: [
                  Icon(
                    Icons.map_rounded,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Campus Location Pinpoint',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Pinpoint the exact spot inside your university campus.',
                style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
              ),
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CampusMapPicker(
                  university: university,
                  isLost: _isLost,
                  initialPosition: _pinnedLocation,
                  onLocationSelected: (position, placeName) {
                    if (!mounted) return;
                    setState(() {
                      _pinnedLocation = position;
                      _resolvedLocationName = placeName;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Optional Indoor / Room Detail
              TextFormField(
                controller: _roomDetailController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Floor / Room / Area Note (Optional)',
                  hintText: 'e.g. 2nd Floor, Room 204 or Near Cafeteria',
                  prefixIcon: Icon(Icons.meeting_room_outlined, color: Color(0xFF71717A)),
                ),
              ),
              const SizedBox(height: 14),

              // Date Picker Field
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
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
                            DateHelper.formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF18181B),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_calendar_rounded,
                        color: Color(0xFFA1A1AA),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide distinguishing features, colors, case details, or markings...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Image Selection Section
              const Text(
                'Photo (Optional, max 10 MB)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),

              if (_selectedImagePath != null &&
                  (kIsWeb || FileHelper.doesLocalImageExist(_selectedImagePath))) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImagePath!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImagePath!),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton.filled(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        onPressed: () {
                          setState(() => _selectedImagePath = null);
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                GestureDetector(
                  onTap: _isSavingImage ? null : _showImagePickerSheet,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: _isSavingImage
                        ? const Center(child: CircularProgressIndicator())
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 28,
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Tap to choose or take a photo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF18181B),
                                ),
                              ),
                              Text(
                                'Saved locally on device (limit 10 MB)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFA1A1AA),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Submit Pill Button (matching reference "Get Started!" deep charcoal pill)
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: lostFoundVM.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.darkColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: lostFoundVM.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLost ? 'Submit Lost Report' : 'Submit Found Report',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
