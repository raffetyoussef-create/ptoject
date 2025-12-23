import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// MODELS - نفس النموذج المستخدم في شاشة المستخدم
// =============================================================================

class Craftsman {
  final String uid;
  final String name;
  final String category;
  final String price;
  final String experience;
  final double rating;
  final bool isAvailable;
  final String? photoUrl;
  final String email;
  final String phone;

  Craftsman({
    required this.uid,
    required this.name,
    required this.category,
    required this.price,
    required this.experience,
    this.rating = 5.0,
    this.isAvailable = true,
    this.photoUrl,
    required this.email,
    required this.phone,
  });

  factory Craftsman.fromMap(Map<String, dynamic> map, String docId) {
    return Craftsman(
      uid: docId,
      name: map['name'] ?? 'حرفي',
      category: map['category'] ?? 'عام',
      price: map['price']?.toString() ?? '100',
      experience: map['experience']?.toString() ?? '5',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      isAvailable: map['isAvailable'] ?? true,
      photoUrl: map['photoUrl'] ?? map['imageUrl'],
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}

// =============================================================================
// CRAFTSMAN HOME SCREEN
// =============================================================================

class CraftsmanHomeScreen extends StatefulWidget {
  const CraftsmanHomeScreen({Key? key}) : super(key: key);

  @override
  State<CraftsmanHomeScreen> createState() => _CraftsmanHomeScreenState();
}

class _CraftsmanHomeScreenState extends State<CraftsmanHomeScreen> {
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color warningColor = const Color(0xFFFF9800);
  final Color successColor = const Color(0xFF4CAF50);
  
  Craftsman? _currentCraftsman;
  bool _isLoading = true;
  int _pendingRequests = 0;
  int _upcomingBookings = 0;
  double _totalEarnings = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadCraftsmanData();
    _loadStatistics();
  }

  Future<void> _loadCraftsmanData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final craftsmanDoc = await FirebaseFirestore.instance
            .collection('craftsmen')
            .doc(user.uid)
            .get();
        
        if (craftsmanDoc.exists) {
          setState(() {
            _currentCraftsman = Craftsman.fromMap(
              craftsmanDoc.data() as Map<String, dynamic>,
              craftsmanDoc.id
            );
            _isLoading = false;
          });
        } else {
          // إذا لم يكن مسجلاً كحرفي، نحمله من users
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
              
          if (userDoc.exists) {
            setState(() {
              _currentCraftsman = Craftsman(
                uid: user.uid,
                name: userDoc.data()?['name'] ?? 'حرفي',
                category: userDoc.data()?['category'] ?? 'عام',
                price: userDoc.data()?['price']?.toString() ?? '100',
                experience: userDoc.data()?['experience']?.toString() ?? '0',
                email: userDoc.data()?['email'] ?? '',
                phone: userDoc.data()?['phone'] ?? '',
              );
              _isLoading = false;
            });
          } else {
            setState(() => _isLoading = false);
          }
        }
      } catch (e) {
        print('Error loading craftsman: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // جلب الطلبات المعلقة (new bookings)
      final pendingRequests = await FirebaseFirestore.instance
          .collection('bookings') // ✅ تم التعديل من requests إلى bookings
          .where('craftsmanId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'new') // ✅ الحالة new هي الطلبات الجديدة
          .get();
      
      // جلب الحجوزات القادمة (Confirmed)
      // ✅ إزالة شرط التاريخ من الاستعلام لتجنب مشكلة Index
      final confirmedBookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('craftsmanId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'confirmed')
          .get();

      // ✅ تصفية الحجوزات القادمة فقط في التطبيق
      final now = DateTime.now();
      final upcomingBookingsCount = confirmedBookingsQuery.docs.where((doc) {
        final data = doc.data();
        if (data['appointmentDate'] == null) return false;
        final date = (data['appointmentDate'] as Timestamp).toDate();
        return date.isAfter(now) || date.isAtSameMomentAs(now);
      }).length;
      
      // جلب الأرباح (من الحجوزات المكتملة)
      final earningsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('craftsmanId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();
      
      double earnings = 0.0;
      for (var doc in earningsQuery.docs) {
        earnings += (doc.data()['price'] as num?)?.toDouble() ?? 0.0;
      }

      setState(() {
        _pendingRequests = pendingRequests.docs.length;
        _upcomingBookings = upcomingBookingsCount; // ✅ استخدام العدد المحسوب
        _totalEarnings = earnings;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _toggleAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentCraftsman == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('craftsmen')
          .doc(user.uid)
          .update({
            'isAvailable': !_currentCraftsman!.isAvailable,
          });
      
      setState(() {
        _currentCraftsman = _currentCraftsman!.copyWith(
          isAvailable: !_currentCraftsman!.isAvailable,
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentCraftsman!.isAvailable 
                ? 'أنت الآن متاح للعمل' 
                : 'أنت الآن غير متاح',
          ),
          backgroundColor: _currentCraftsman!.isAvailable ? successColor : Colors.grey,
        ),
      );
    } catch (e) {
      print('Error updating availability: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _isLoading ? _buildLoading() : _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // =============================================================================
  // HEADER
  // =============================================================================
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              Text(
                _isLoading ? 'جاري التحميل...' : 'مرحباً ${_currentCraftsman?.name ?? "حرفي"}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/craftsman_notifications'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_currentCraftsman != null) _buildAvailabilityToggle(),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentCraftsman!.isAvailable ? Icons.check_circle : Icons.pause_circle,
            color: _currentCraftsman!.isAvailable ? Colors.white : Colors.amber,
          ),
          const SizedBox(width: 10),
          Text(
            _currentCraftsman!.isAvailable ? 'متاح للعمل الآن' : 'غير متاح حالياً',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),
          Switch(
            value: _currentCraftsman!.isAvailable,
            onChanged: (_) => _toggleAvailability(),
            activeColor: Colors.white,
            activeTrackColor: successColor,
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // CONTENT
  // =============================================================================
  
  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // الإحصائيات
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatsGrid(),
                const SizedBox(height: 30),
                _buildCraftsmanProfile(),
              ],
            ),
          ),
        ),
        
        // الوظائف السريعة
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الوظائف السريعة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
        
        // الحجوزات القادمة
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الحجوزات القادمة',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/craftsman_bookings'),
                      child: const Text('عرض الكل'),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildUpcomingBookings(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // =============================================================================
  // STATS GRID
  // =============================================================================
  
  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'طلبات جديدة',
          value: '$_pendingRequests',
          icon: Icons.notifications_active,
          color: warningColor,
          onTap: () => Navigator.pushNamed(context, '/craftsman_requests'),
        ),
        _buildStatCard(
          title: 'حجوزات قادمة',
          value: '$_upcomingBookings',
          icon: Icons.calendar_today,
          color: primaryColor,
          onTap: () => Navigator.pushNamed(context, '/craftsman_bookings'),
        ),
        _buildStatCard(
          title: 'إجمالي الأرباح',
          value: '${_totalEarnings.toStringAsFixed(0)} ج.م',
          icon: Icons.monetization_on,
          color: successColor,
          onTap: () => Navigator.pushNamed(context, '/craftsman_earnings'),
        ),
        _buildStatCard(
          title: 'التقييم العام',
          value: _currentCraftsman?.rating.toStringAsFixed(1) ?? '5.0',
          icon: Icons.star,
          color: Colors.amber,
          onTap: () => Navigator.pushNamed(context, '/craftsman_reviews'),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // CRAFTSMAN PROFILE
  // =============================================================================
  
  Widget _buildCraftsmanProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة الحرفي
          CircleAvatar(
            radius: 40,
            backgroundColor: primaryColor.withOpacity(0.2),
            child: _currentCraftsman?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      _currentCraftsman!.photoUrl!,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 40,
                    color: primaryColor,
                  ),
          ),
          const SizedBox(width: 20),
          
          // معلومات الحرفي
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentCraftsman?.name ?? 'حرفي',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _currentCraftsman?.category ?? 'تخصص عام',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      _currentCraftsman?.rating.toStringAsFixed(1) ?? '5.0',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.work_history, color: Colors.grey, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      '${_currentCraftsman?.experience ?? '0'} سنة خبرة',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${_currentCraftsman?.price ?? '0'} ج.م/ساعة',
                  style: TextStyle(
                    color: successColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // زر التعديل
          IconButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/craftsman_edit_profile',
              arguments: _currentCraftsman,
            ),
            icon: Icon(Icons.edit, color: primaryColor),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // QUICK ACTIONS
  // =============================================================================
  
  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'الطلبات الجديدة',
        'icon': Icons.notifications,
        'color': warningColor,
        'route': '/craftsman_requests',
      },
      {
        'title': 'جدول الحجوزات',
        'icon': Icons.calendar_month,
        'color': primaryColor,
        'route': '/craftsman_schedule',
      },
      {
        'title': 'المحادثات',
        'icon': Icons.chat,
        'color': Colors.blue,
        'route': '/craftsman_chats',
      },
      {
        'title': 'المدفوعات',
        'icon': Icons.payment,
        'color': successColor,
        'route': '/craftsman_payments',
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.8,
      children: actions.map((action) {
        return _buildQuickActionCard(
          title: action['title'] as String,
          icon: action['icon'] as IconData,
          color: action['color'] as Color,
          onTap: () => Navigator.pushNamed(context, action['route'] as String),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // UPCOMING BOOKINGS
  // =============================================================================
  
  Widget _buildUpcomingBookings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('craftsmanId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isEqualTo: 'confirmed')
          // .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.now()) // ❌ إزالة لعدم وجود Index
          // .orderBy('appointmentDate') // ❌ إزالة الترتيب أيضاً
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ الفرز والتصفية في التطبيق
        var bookings = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['appointmentDate'] == null) return false;
          final date = (data['appointmentDate'] as Timestamp).toDate();
          return date.isAfter(DateTime.now().subtract(const Duration(days: 1))); // إظهار حجوزات اليوم والمستقبل
        }).toList();

        // ترتيب حسب التاريخ
        bookings.sort((a, b) {
           final dateA = ((a.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp).toDate();
           final dateB = ((b.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp).toDate();
           return dateA.compareTo(dateB);
        });

        // أخذ أول 3 فقط
        if (bookings.length > 3) {
          bookings = bookings.sublist(0, 3);
        }
        
        if (bookings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.calendar_today, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 20),
                const Text(
                  'لا توجد حجوزات قادمة',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/craftsman_bookings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('عرض جميع الحجوزات'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index].data() as Map<String, dynamic>;
            final date = (booking['appointmentDate'] as Timestamp).toDate(); // ✅ تصحيح الاسم
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_today, color: primaryColor),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['serviceType'] ?? 'خدمة', // ✅ تصحيح الاسم
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_formatDate(date)} - ${booking['appointmentTime'] ?? ''}', // ✅ تصحيح الاسم
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${booking['expectedPrice']?.toString() ?? '0'} ج.م', // ✅ تصحيح الاسم
                    style: TextStyle(
                      color: successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // =============================================================================
  // DRAWER
  // =============================================================================
  
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: _currentCraftsman?.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _currentCraftsman!.photoUrl!,
                            fit: BoxFit.cover,
                            width: 70,
                            height: 70,
                          ),
                        )
                      : const Icon(Icons.person, size: 40, color: Color(0xFF6C63FF)),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentCraftsman?.name ?? 'حرفي',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  _currentCraftsman?.category ?? 'تخصص عام',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _drawerTile(Icons.person, 'الملف الشخصي', () => Navigator.pushNamed(context, '/craftsman_profile')),
          _drawerTile(Icons.request_page, 'طلبات العمل', () => Navigator.pushNamed(context, '/craftsman_requests')),
          _drawerTile(Icons.calendar_month, 'الحجوزات', () => Navigator.pushNamed(context, '/craftsman_bookings')),
          _drawerTile(Icons.schedule, 'جدول المواعيد', () => Navigator.pushNamed(context, '/craftsman_schedule')),
          _drawerTile(Icons.chat, 'المحادثات', () => Navigator.pushNamed(context, '/craftsman_chats')),
          _drawerTile(Icons.star, 'التقييمات', () => Navigator.pushNamed(context, '/craftsman_reviews')),
          _drawerTile(Icons.attach_money, 'الأرباح', () => Navigator.pushNamed(context, '/craftsman_earnings')),
          _drawerTile(Icons.payment, 'المدفوعات', () => Navigator.pushNamed(context, '/craftsman_payments')),
          const Divider(),
          _drawerTile(Icons.settings, 'الإعدادات', () => Navigator.pushNamed(context, '/craftsman_settings')),
          _drawerTile(Icons.help, 'المساعدة والدعم', () => Navigator.pushNamed(context, '/craftsman_help')),
          _drawerTile(Icons.logout, 'تسجيل الخروج', _signOut, isExit: true),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap, {bool isExit = false}) {
    return ListTile(
      leading: Icon(icon, color: isExit ? Colors.red : primaryColor),
      title: Text(title, style: TextStyle(color: isExit ? Colors.red : Colors.black)),
      onTap: onTap,
    );
  }

  // =============================================================================
  // BOTTOM NAV
  // =============================================================================
  
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              // الرئيسية (نحن فيها)
              break;
            case 1:
              Navigator.pushNamed(context, '/craftsman_requests');
              break;
            case 2:
              Navigator.pushNamed(context, '/craftsman_schedule');
              break;
            case 3:
              Navigator.pushNamed(context, '/craftsman_chats');
              break;
            case 4:
              Navigator.pushNamed(context, '/craftsman_profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'الجدول'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'المحادثات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الحساب'),
        ],
      ),
    );
  }

  // =============================================================================
  // SIGN OUT
  // =============================================================================
  
  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}

// =============================================================================
// EXTENSIONS
// =============================================================================

extension CraftsmanExtensions on Craftsman {
  Craftsman copyWith({
    String? uid,
    String? name,
    String? category,
    String? price,
    String? experience,
    double? rating,
    bool? isAvailable,
    String? photoUrl,
    String? email,
    String? phone,
  }) {
    return Craftsman(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
      isAvailable: isAvailable ?? this.isAvailable,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}