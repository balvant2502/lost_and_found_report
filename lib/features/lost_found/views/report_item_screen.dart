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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Item Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Max image size is 10 MB. Saved locally on device.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a Photo'),
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
    if (_selectedImagePath != null) {
      setState(() => _isSavingImage = true);
      try {
        uploadedImageUrl = await CloudinaryService.uploadImage(
          _selectedImagePath!,
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isSavingImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image upload failed: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      if (mounted) setState(() => _isSavingImage = false);
    }

    final success = await lostFoundVM.createReport(
      title: _titleController.text,
      description: _descController.text,
      category: _selectedCategory,
      location: finalLocation,
      latitude: _pinnedLocation!.latitude,
      longitude: _pinnedLocation!.longitude,
      date: _selectedDate,
      isLost: _isLost,
      reportedBy: user.uid,
      reporterName: user.name,
      university: user.university,
      imageUrl: uploadedImageUrl,
    );

    if (mounted) {
      if (success) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!();
        } else {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLost
                  ? 'Lost item reported with campus pinpoint!'
                  : 'Found item reported with campus pinpoint!',
            ),
            backgroundColor: AppTheme.foundColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lostFoundVM.errorMessage ?? 'Failed to submit report'),
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
      appBar: AppBar(
        title: const Text('Create Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.campaign_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Help your campus community reunite with a lost item.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Report Type Selector
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isLost = true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isLost
                              ? AppTheme.lostColor
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isLost
                                ? AppTheme.lostColor
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          'I Lost an Item',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _isLost ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isLost = false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isLost
                              ? AppTheme.foundColor
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_isLost
                                ? AppTheme.foundColor
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          'I Found an Item',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: !_isLost
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 20),

              // University Region Pinpoint Map (Replaced Text Input)
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pinpoint the exact spot inside your university campus.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),

              CampusMapPicker(
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
              const SizedBox(height: 12),

              // Optional Indoor / Room Detail
              TextFormField(
                controller: _roomDetailController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Floor / Room / Area Note (Optional)',
                  hintText: 'e.g. 2nd Floor, Room 204 or Near Vending Machine',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker Field
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
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
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            DateHelper.formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_calendar_rounded,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText:
                      'Provide distinguishing features, colors, case details, or markings...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Image Selection Section (Saved Locally, <= 10 MB)
              const Text(
                'Photo (Optional, max 10 MB)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),

              if (_selectedImagePath != null &&
                  (kIsWeb || FileHelper.doesLocalImageExist(_selectedImagePath))) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
                    IconButton.filled(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      onPressed: () {
                        setState(() => _selectedImagePath = null);
                      },
                    ),
                  ],
                ),
              ] else ...[
                InkWell(
                  onTap: _isSavingImage ? null : _showImagePickerSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _isSavingImage
                        ? const Center(child: CircularProgressIndicator())
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 32,
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Tap to choose or take a photo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                'Saved locally on device (limit 10 MB)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: lostFoundVM.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
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
                        _isLost ? 'Post Lost Report' : 'Post Found Report',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
