import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFaqFilter = 'All';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFaqTab(),
                  _buildContactUsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
                color: Colors.white,
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
            ),
          ),
          const Text(
            'Help Center',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 15),
            prefixIcon: Icon(Icons.search, color: Color(0xFF999999)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF777777),
        unselectedLabelColor: const Color(0xFF999999),
        indicatorColor: const Color(0xFF777777),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'FAQ'),
          Tab(text: 'Contact Us'),
        ],
      ),
    );
  }

  Widget _buildFaqFilterChips() {
    final filters = ['All', 'Services', 'General', 'Account'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFaqFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFaqFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF777777) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF777777),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaqTab() {
    final faqs = [
      'Can I track my order\'s delivery status?',
      'Is there a return policy?',
      'Can I save my favorite items for later?',
      'Can I share products with my friends?',
      'How do I contact customer support?',
      'What payment methods are accepted?',
      'How to add review?'
    ];
    return Column(
      children: [
        _buildFaqFilterChips(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0,
                    iconColor: const Color(0xFF777777),
                    collapsedIconColor: const Color(0xFF999999),
                    title: Text(
                      faqs[index],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: const Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF777777), height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactUsTab() {
    final contacts = [
      {'title': 'Customer Service', 'icon': Icons.headset_mic_outlined, 'detail': 'Available 24/7 at 1-800-123-4567'},
      {'title': 'WhatsApp', 'icon': Icons.chat_outlined, 'detail': '(480) 555-0103'},
      {'title': 'Website', 'icon': Icons.language_outlined, 'detail': 'www.jewelryapp.com'},
      {'title': 'Facebook', 'icon': Icons.facebook, 'detail': '/jewelryapp'},
      {'title': 'Twitter', 'icon': Icons.alternate_email, 'detail': '@jewelryapp'},
      {'title': 'Instagram', 'icon': Icons.camera_alt_outlined, 'detail': '@jewelryapp_official'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: index == 1,
              iconColor: const Color(0xFF777777),
              collapsedIconColor: const Color(0xFF999999),
              leading: Icon(contact['icon'] as IconData, color: const Color(0xFF555555)),
              title: Text(
                contact['title'] as String,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFF999999)),
                      const SizedBox(width: 12),
                      Text(
                        contact['detail'] as String,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF777777)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
