import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/luxury_toast.dart';

class SellerEditProfileScreen extends StatefulWidget {
  final String sellerId;
  const SellerEditProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerEditProfileScreen> createState() => _SellerEditProfileScreenState();
}

class _SellerEditProfileScreenState extends State<SellerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _channelLinkController = TextEditingController();
  String _avatarUrl = '';
  String _coverUrl = '';
  String _mainPlatform = '';
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;
  Map<String, double> _ratings = {};
  int _followersCount = 0;
  int _favoritesCount = 0;
  double _returningCustomers = 0;
  double _calculatedScore = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(widget.sellerId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _channelLinkController.text = data['channelLink'] ?? '';
        _avatarUrl = data['avatar'] ?? '';
        _coverUrl = data['coverImage'] ?? '';
        _mainPlatform = data['mainPlatform'] ?? '';
        _followersCount = (data['followersCount'] as num?)?.toInt() ?? 0;
        _favoritesCount = (data['favoritesCount'] as num?)?.toInt() ?? 0;
        _returningCustomers = (data['returningCustomers'] as num?)?.toDouble() ?? 0;

        final ratingsRaw = data['ratings'];
        if (ratingsRaw is Map) {
          _ratings = ratingsRaw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
        }
        _calculatedScore = _calculateSellerScore();
      });
    }
  }

  double _calculateSellerScore() {
    // Rating formula:
    // followers: 15%, likes: 10%, reviews (avg score): 30%,
    // returning customers: 25%, photo reviews: 20%
    double avgRating = 0;
    if (_ratings.isNotEmpty) {
      avgRating = _ratings.values.reduce((a, b) => a + b) / _ratings.length;
    }

    final normalized = {
      'followers': (_followersCount / 1000).clamp(0, 1).toDouble(),
      'likes': (_favoritesCount / 500).clamp(0, 1).toDouble(),
      'reviews': (avgRating / 5).clamp(0, 1).toDouble(),
      'returning': (_returningCustomers / 100).clamp(0, 1).toDouble(),
    };

    final score = (
      normalized['followers']! * 0.15 +
      normalized['likes']! * 0.10 +
      normalized['reviews']! * 0.30 +
      normalized['returning']! * 0.25 +
      normalized['reviews']! * 0.20 // photo reviews approximation
    ) * 5;

    return score.clamp(0, 5);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _channelLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      body: CustomScrollView(
        slivers: [
          // Cover image area
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: AppColors.canvasParchment,
            pinned: true,
            leading: IconButton(
              icon: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _coverUrl.isNotEmpty
                      ? Image.network(_coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildCoverPlaceholder())
                      : _buildCoverPlaceholder(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, right: 16,
                    child: GestureDetector(
                      onTap: _pickCoverImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isUploadingCover)
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            else
                              const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.hairline,
                              backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                              child: _avatarUrl.isEmpty ? const Icon(Icons.person, size: 40, color: AppColors.inkMuted48) : null,
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.canvas, width: 2),
                                ),
                                child: _isUploadingAvatar
                                    ? const Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Seller Score
                    _buildScoreCard(),
                    const SizedBox(height: 24),

                    // Ratings breakdown
                    if (_ratings.isNotEmpty) ...[
                      _buildRatingsBreakdown(),
                      const SizedBox(height: 24),
                    ],

                    // Form fields
                    _buildTextField('Store Name', _nameController, Icons.store),
                    const SizedBox(height: 16),
                    _buildTextField('Bio / Description', _descriptionController, Icons.description, maxLines: 4),
                    const SizedBox(height: 16),
                    _buildTextField('Social Media Link', _channelLinkController, Icons.link),
                    const SizedBox(height: 16),
                    _buildPlatformPicker(),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _calculatedScore >= 4.0 ? const Color(0xFFFFD700) : const Color(0xFFF5F5F7),
            _calculatedScore >= 4.0 ? const Color(0xFFFFF8DC) : const Color(0xFFFFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _calculatedScore >= 4.0 ? const Color(0xFFFFD700).withOpacity(0.5) : AppColors.hairline),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(_calculatedScore.toStringAsFixed(1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.ink)),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < _calculatedScore.round() ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFD700), size: 16,
                )),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seller Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                  'Based on followers, reviews, returning customers and ratings',
                  style: TextStyle(fontSize: 11, color: AppColors.inkMuted48, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniMetric(Icons.people, '$_followersCount'),
                    const SizedBox(width: 12),
                    _buildMiniMetric(Icons.favorite, '$_favoritesCount'),
                    const SizedBox(width: 12),
                    _buildMiniMetric(Icons.replay, '${_returningCustomers.toStringAsFixed(0)}%'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.inkMuted48),
        const SizedBox(width: 3),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink)),
      ],
    );
  }

  Widget _buildRatingsBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Quality', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 12),
          ..._ratings.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 140, child: Text(_formatRatingKey(entry.key), style: TextStyle(fontSize: 13, color: AppColors.inkMuted48))),
                Expanded(
                  child: Row(
                    children: List.generate(5, (i) => Icon(
                      i < entry.value.round() ? Icons.star : (i < entry.value ? Icons.star_half : Icons.star_border),
                      color: const Color(0xFFFFD700), size: 16,
                    )),
                  ),
                ),
                Text(entry.value.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  String _formatRatingKey(String key) {
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').trim();
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.inkMuted48, size: 20) : null,
            filled: true,
            fillColor: AppColors.canvas,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.hairline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.hairline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformPicker() {
    final platforms = ['TikTok', 'YouTube', 'Instagram', 'Facebook', 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Main Platform', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: platforms.map((p) => ChoiceChip(
            label: Text(p),
            selected: _mainPlatform == p,
            selectedColor: AppColors.primary.withOpacity(0.15),
            labelStyle: TextStyle(color: _mainPlatform == p ? AppColors.primary : AppColors.inkMuted48, fontSize: 13),
            side: BorderSide(color: _mainPlatform == p ? AppColors.primary.withOpacity(0.3) : AppColors.hairline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (_) => setState(() => _mainPlatform = p),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: const Color(0xFF2A2A2C),
      child: const Center(child: Icon(Icons.panorama, color: Colors.white24, size: 60)),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final ref = FirebaseStorage.instance.ref('seller_avatars/${widget.sellerId}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) LuxuryToast.show(context, message: 'Upload failed');
    } finally {
      setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingCover = true);
    try {
      final ref = FirebaseStorage.instance.ref('seller_covers/${widget.sellerId}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      setState(() => _coverUrl = url);
    } catch (e) {
      if (mounted) LuxuryToast.show(context, message: 'Upload failed');
    } finally {
      setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('sellers').doc(widget.sellerId).update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'channelLink': _channelLinkController.text.trim(),
        'mainPlatform': _mainPlatform,
        'avatar': _avatarUrl,
        'coverImage': _coverUrl,
      });
      if (mounted) {
        LuxuryToast.show(context, message: 'Profile updated!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) LuxuryToast.show(context, message: 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
