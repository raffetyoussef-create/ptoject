import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class CraftsmanProfileScreen extends StatefulWidget {
  const CraftsmanProfileScreen({Key? key}) : super(key: key);

  @override
  State<CraftsmanProfileScreen> createState() => _CraftsmanProfileScreenState();
}

class _CraftsmanProfileScreenState extends State<CraftsmanProfileScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isAvailable = true;

  // لوحة ألوان فخمة وعصرية
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color accentColor = const Color(0xFFFF6B6B);
  final Color warningColor = const Color(0xFFFFA502);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color darkColor = const Color(0xFF2C3E50);

  // دالة تسجيل الخروج الاحترافية مع التأكيد
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text('تسجيل الخروج', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟', textAlign: TextAlign.right),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('خروج', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('craftsmen').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return _buildNotFoundView();

          var data = snapshot.data!.data() as Map<String, dynamic>;
          _isAvailable = data['isAvailable'] ?? true;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. الجزء العلوي المطور (Modern Sliver Header)
              _buildHeader(data),

              // 2. بطاقة الحالة التفاعلية
              _buildAvailabilityCard(),

              // 3. لوحة الإحصائيات (Stats Dashboard)
              _buildStatsGrid(data),

              // 4. القوائم الإدارية (Management Menu)
              _buildSectionTitle('إدارة أعمالك'),
              _buildManagementMenu(context),

              // 5. معلومات التواصل
              _buildSectionTitle('بيانات الحساب العامة'),
              _buildAccountInfo(data),

              // 6. زر تسجيل الخروج العائم
              _buildLogoutButton(context),
              
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // تدرج لوني للخلفية
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // دوائر مزخرفة في الخلفية
            Positioned(top: -50, right: -50, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.1))),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildProfileAvatar(data['imageUrl']),
                const SizedBox(height: 15),
                Text(data['name'] ?? 'حرفي مميز', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(data['category'] ?? 'فني محترف', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/edit_craftsman_profile'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(String? url) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: CircleAvatar(
        radius: 55,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null ? Icon(Icons.person, size: 60, color: primaryColor) : null,
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: darkColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            _buildStatusIndicator(_isAvailable),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('جاهزية العمل', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(_isAvailable ? 'أنت متاح لاستقبال الطلبات' : 'أنت في وضع الراحة الآن', 
                    style: TextStyle(color: darkColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            Switch.adaptive(
              value: _isAvailable,
              activeColor: secondaryColor,
              onChanged: (val) async {
                await FirebaseFirestore.instance.collection('craftsmen').doc(currentUser!.uid).update({'isAvailable': val});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            _buildStatCard(Icons.star_rounded, data['rating']?.toStringAsFixed(1) ?? '5.0', 'التقييم', warningColor),
            const SizedBox(width: 12),
            _buildStatCard(Icons.verified_user_rounded, '${data['completedJobs'] ?? 0}', 'المهام', secondaryColor),
            const SizedBox(width: 12),
            _buildStatCard(Icons.payments_rounded, '${data['price'] ?? 0}', 'السعر/س', primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementMenu(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildMenuTile(Icons.calendar_month_rounded, 'إدارة الطلبات والحجوزات', 'متابعة المهام الجديدة والجارية', primaryColor, () => Navigator.pushNamed(context, '/craftsman_jobs')),
          _buildMenuTile(Icons.photo_library_rounded, 'معرض الأعمال (Portfolio)', 'أضف صوراً لأفضل إنجازاتك', secondaryColor, () => Navigator.pushNamed(context, '/portfolio_management')),
          _buildMenuTile(Icons.reviews_rounded, 'آراء وتقييمات العملاء', 'شاهد انطباعات من تعاملوا معك', Colors.orange, () => Navigator.pushNamed(context, '/reviews')),
        ]),
      ),
    );
  }

  Widget _buildAccountInfo(Map<String, dynamic> data) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            _buildDetailRow(Icons.email_outlined, 'البريد الإلكتروني', data['email'] ?? 'غير متوفر'),
            const Divider(height: 30),
            _buildDetailRow(Icons.phone_iphone_rounded, 'رقم التواصل', data['phone'] ?? 'غير متوفر'),
            const Divider(height: 30),
            _buildDetailRow(Icons.location_on_outlined, 'منطقة العمل', data['address'] ?? 'غير محددة'),
            const Divider(height: 30),
            _buildDetailRow(Icons.history_edu_rounded, 'سنوات الخبرة', '${data['experience'] ?? 0} سنوات'),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: OutlinedButton.icon(
          onPressed: () => _handleLogout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('تسجيل الخروج من الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: BorderSide(color: accentColor, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
    );
  }

  // --- أدوات التصميم (UI Helpers) ---

  Widget _buildStatCard(IconData icon, String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, color: primaryColor.withOpacity(0.5), size: 22),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: darkColor, fontSize: 15)),
        ])),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 25, 25, 15),
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
      ),
    );
  }

  Widget _buildStatusIndicator(bool active) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: active ? secondaryColor : Colors.grey,
        shape: BoxShape.circle,
        boxShadow: active ? [BoxShadow(color: secondaryColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)] : [],
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.person_off_rounded, size: 80, color: Colors.grey), const SizedBox(height: 16), const Text('لم نتمكن من العثور على ملفك الشخصي'), TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('تسجيل الخروج'))])));
  }
}