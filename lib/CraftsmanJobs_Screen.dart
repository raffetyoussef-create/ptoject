import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class CraftsmanJobsScreen extends StatefulWidget {
  const CraftsmanJobsScreen({Key? key}) : super(key: key);

  @override
  State<CraftsmanJobsScreen> createState() => _CraftsmanJobsScreenState();
}

class _CraftsmanJobsScreenState extends State<CraftsmanJobsScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _fabController;
  late AnimationController _headerController;
  late Animation<double> _fabAnimation;
  late Animation<double> _headerAnimation;

  final List<String> _tabs = ['الجديدة', 'قيد التنفيذ', 'المكتملة', 'الملغاة'];
  final List<Color> _tabColors = [
    const Color(0xFF6C63FF),
    const Color(0xFFFF9800),
    const Color(0xFF4CAF50),
    const Color(0xFFE53935),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _fabController.forward();
    _headerController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  String _getStatusFromTab(int tab) {
    switch (tab) {
      case 0:
        return 'new';
      case 1:
        return 'in_progress';
      case 2:
        return 'completed';
      case 3:
        return 'cancelled';
      default:
        return 'new';
    }
  }

  Future<void> _updateJobStatus(String jobId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .update({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث حالة الطلب بنجاح', textAlign: TextAlign.right),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ في التحديث', textAlign: TextAlign.right),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar with Animation
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6C63FF),
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _headerAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6C63FF),
                        const Color(0xFF5A52D5),
                        const Color(0xFF4A42C5),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'طلبات العمل',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('jobs')
                                  .where('craftsmanId', isEqualTo: userId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int total = snapshot.data?.docs.length ?? 0;
                                return Text(
                                  'لديك $total طلب',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tabs Section
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsDelegate(
              minHeight: 70,
              maxHeight: 70,
              child: Container(
                color: const Color(0xFFF5F7FA),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _tabs.length,
                  itemBuilder: (context, index) {
                    return _buildTabChip(index);
                  },
                ),
              ),
            ),
          ),

          // Jobs List
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('craftsmanId', isEqualTo: userId)
                  .where('status', isEqualTo: _getStatusFromTab(_selectedTab))
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _tabColors[_selectedTab],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = snapshot.data!.docs[index];
                      return _buildJobCard(job, index);
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            // Navigate to statistics or filters
          },
          backgroundColor: const Color(0xFF6C63FF),
          elevation: 8,
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('إحصائيات'),
        ),
      ),
    );
  }

  Widget _buildTabChip(int index) {
    bool isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: () {
            setState(() => _selectedTab = index);
            _fabController.reset();
            _fabController.forward();
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [_tabColors[index], _tabColors[index].withOpacity(0.7)],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _tabColors[index].withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              _tabs[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(DocumentSnapshot job, int index) {
    final data = job.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'new';

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showJobDetails(job),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _tabColors[_selectedTab].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: _tabColors[_selectedTab],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            data['title'] ?? 'بدون عنوان',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['customerName'] ?? 'عميل',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    data['description'] ?? 'لا يوجد وصف',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Action Buttons
                      if (status == 'new')
                        Row(
                          children: [
                            _buildActionButton(
                              icon: Icons.close,
                              color: Colors.red,
                              onTap: () => _updateJobStatus(job.id, 'cancelled'),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.check,
                              color: Colors.green,
                              onTap: () => _updateJobStatus(job.id, 'in_progress'),
                            ),
                          ],
                        ),
                      if (status == 'in_progress')
                        _buildActionButton(
                          icon: Icons.done_all,
                          color: Colors.blue,
                          label: 'إكمال',
                          onTap: () => _updateJobStatus(job.id, 'completed'),
                        ),
                      
                      // Price & Date
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(data['createdAt']),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${data['price'] ?? 0} ج.م',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    String? label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(icon, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: _tabColors[_selectedTab].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline,
              size: 80,
              color: _tabColors[_selectedTab],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد طلبات ${_tabs[_selectedTab]}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ستظهر الطلبات هنا عند توفرها',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showJobDetails(DocumentSnapshot job) {
    final data = job.data() as Map<String, dynamic>;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data['title'] ?? 'بدون عنوان',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('العميل', data['customerName'] ?? 'غير محدد'),
                    _buildDetailRow('السعر', '${data['price'] ?? 0} ج.م'),
                    _buildDetailRow('التاريخ', _formatDate(data['createdAt'])),
                    _buildDetailRow('الحالة', _getStatusText(data['status'])),
                    const SizedBox(height: 20),
                    const Text(
                      'الوصف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['description'] ?? 'لا يوجد وصف',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'new':
        return 'جديد';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير محدد';
    }
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _TabsDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_TabsDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}