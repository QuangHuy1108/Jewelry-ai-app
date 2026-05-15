import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/luxury_toast.dart';

class SellerMediaHubScreen extends StatefulWidget {
  const SellerMediaHubScreen({super.key});

  @override
  State<SellerMediaHubScreen> createState() => _SellerMediaHubScreenState();
}

class _SellerMediaHubScreenState extends State<SellerMediaHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = ['All', 'Rings', 'Necklaces', 'Earrings', 'Bracelets'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: () => Navigator.pop(context)),
        title: const Text('Media Hub', style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.inkMuted48,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.photo_library, size: 20), text: 'Images'),
            Tab(icon: Icon(Icons.videocam, size: 20), text: 'Videos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImageTab(),
          _buildVideoTab(),
        ],
      ),
    );
  }

  Widget _buildImageTab() {
    return Column(
      children: [
        // Category filter chips
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_categories[index]),
                  selected: index == 0,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: index == 0 ? AppColors.primary : AppColors.inkMuted48,
                    fontSize: 13, fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppColors.canvas,
                  side: BorderSide(color: index == 0 ? AppColors.primary.withOpacity(0.3) : AppColors.hairline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (_) {},
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('media_assets')
                .where('type', isEqualTo: 'image')
                .orderBy('createdAt', descending: true)
                .limit(30)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return _buildEmptyMediaState('images');

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildImageTile(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(Map<String, dynamic> data) {
    final url = data['url'] ?? '';
    final thumbnailUrl = data['thumbnailUrl'] ?? url;
    final title = data['title'] ?? 'Product Image';
    final category = data['category'] ?? '';
    final downloads = data['downloadCount'] ?? 0;

    return GestureDetector(
      onTap: () => _showImagePreview(data),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: thumbnailUrl.isNotEmpty
                    ? Image.network(thumbnailUrl, fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (_, __, ___) => _buildPlaceholder())
                    : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.canvasParchment, borderRadius: BorderRadius.circular(4)),
                          child: Text(category, style: TextStyle(fontSize: 9, color: AppColors.inkMuted48)),
                        ),
                      const Spacer(),
                      Icon(Icons.download, size: 12, color: AppColors.inkMuted48),
                      const SizedBox(width: 2),
                      Text('$downloads', style: TextStyle(fontSize: 10, color: AppColors.inkMuted48)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('media_assets')
          .where('type', isEqualTo: 'video')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyMediaState('videos');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildVideoTile(data);
          },
        );
      },
    );
  }

  Widget _buildVideoTile(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Template Video';
    final category = data['category'] ?? '';
    final thumbnailUrl = data['thumbnailUrl'] ?? '';
    final downloads = data['downloadCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          // Video thumbnail
          Container(
            width: 100, height: 70,
            decoration: BoxDecoration(
              color: AppColors.canvasParchment,
              borderRadius: BorderRadius.circular(12),
              image: thumbnailUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(thumbnailUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: thumbnailUrl.isEmpty
                ? const Center(child: Icon(Icons.play_circle_fill, color: AppColors.inkMuted48, size: 36))
                : Center(
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  if (category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.canvasParchment, borderRadius: BorderRadius.circular(4)),
                      child: Text(category, style: TextStyle(fontSize: 10, color: AppColors.inkMuted48)),
                    ),
                  const SizedBox(width: 8),
                  Icon(Icons.download, size: 12, color: AppColors.inkMuted48),
                  const SizedBox(width: 2),
                  Text('$downloads', style: TextStyle(fontSize: 10, color: AppColors.inkMuted48)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: IconButton(
              onPressed: () => LuxuryToast.show(context, message: 'Downloading video...'),
              icon: const Icon(Icons.download, color: AppColors.primary, size: 18),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMediaState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type == 'images' ? Icons.photo_library_outlined : Icons.videocam_off_outlined, size: 56, color: AppColors.inkMuted48),
          const SizedBox(height: 16),
          Text('No $type available yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.inkMuted48)),
          const SizedBox(height: 4),
          Text('Admin will upload media assets soon', style: TextStyle(fontSize: 13, color: AppColors.inkMuted48)),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.canvasParchment,
      child: const Center(child: Icon(Icons.image_outlined, color: AppColors.inkMuted48, size: 40)),
    );
  }

  void _showImagePreview(Map<String, dynamic> data) {
    final url = data['url'] ?? '';
    final title = data['title'] ?? 'Product Image';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: url.isNotEmpty
                  ? Image.network(url, fit: BoxFit.contain)
                  : _buildPlaceholder(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    LuxuryToast.show(context, message: 'Saved to gallery');
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
