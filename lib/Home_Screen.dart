import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// MODELS - محدثة مع الحقول الإضافية
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
  final String? email; // حقل البريد الإلكتروني
  final String? phone; // حقل الهاتف

  Craftsman({
    required this.uid,
    required this.name,
    required this.category,
    required this.price,
    required this.experience,
    this.rating = 5.0,
    this.isAvailable = true,
    this.photoUrl,
    this.email,
    this.phone,
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
      email: map['email'], // تعيين البريد الإلكتروني
      phone: map['phone'], // تعيين الهاتف
    );
  }

  // دالة لتحويل البيانات إلى Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'category': category,
      'price': price,
      'experience': experience,
      'rating': rating,
      'isAvailable': isAvailable,
      'photoUrl': photoUrl,
      'email': email,
      'phone': phone,
    };
  }
}

// =============================================================================
// HOME SCREEN - الصفحة الرئيسية
// =============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  String _userName = 'مستخدم';
  
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'الكل', 'icon': Icons.dashboard, 'color': const Color(0xFF6C63FF)},
    {'name': 'سباك', 'icon': Icons.plumbing, 'color': const Color(0xFF4A90E2)},
    {'name': 'كهربائي', 'icon': Icons.bolt, 'color': const Color(0xFFFF9800)},
    {'name': 'نجار', 'icon': Icons.handyman, 'color': const Color(0xFF795548)},
    {'name': 'دهان', 'icon': Icons.format_paint, 'color': const Color(0xFFE91E63)},
    {'name': 'تكييف', 'icon': Icons.ac_unit, 'color': const Color(0xFF00BCD4)},
    {'name': 'نقاش', 'icon': Icons.brush, 'color': const Color(0xFF9C27B0)},
    {'name': 'سيراميك', 'icon': Icons.grid_view, 'color': const Color(0xFF607D8B)},
    {'name': 'أعمال ألمنيوم', 'icon': Icons.window, 'color': const Color(0xFF546E7A)},
    {'name': 'حداد', 'icon': Icons.build, 'color': const Color(0xFF3E2723)},
    {'name': 'أخرى', 'icon': Icons.more_horiz, 'color': const Color(0xFF9E9E9E)},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) { // إضافة شرط mounted لمنع الأخطاء
          setState(() => _userName = userDoc.data()?['name'] ?? 'مستخدم');
        }
      } catch (e) {
        print('Error loading user: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // =============================================================================
  // HEADER - رأس الصفحة
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
                'مرحباً $_userName',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'ابحث عن حرفي...',
          prefixIcon: Icon(Icons.search, color: primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  // =============================================================================
  // CONTENT - محتوى الصفحة
  // =============================================================================
  
  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // الفئات
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('الفئات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) => _buildCategoryCard(_categories[i]),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('الحرفيون المتاحون', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        
        // قائمة الحرفيين من Firebase
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('craftsmen')
              .where('userType', isEqualTo: 'craftsman') // فلترة للحرفيين فقط
              .where('isAvailable', isEqualTo: true) // عرض الحرفيين المتاحين فقط
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      const Text('حدث خطأ في تحميل البيانات'),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, color: Colors.grey, size: 60),
                      SizedBox(height: 10),
                      Text('لا يوجد حرفيون مسجلون بعد'),
                      SizedBox(height: 5),
                      Text('كن أول حرفي ينضم إلينا!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }

            var craftsmen = snapshot.data!.docs.map((doc) {
              return Craftsman.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();

            // فلترة حسب البحث والفئة
            if (_searchQuery.isNotEmpty) {
              craftsmen = craftsmen.where((c) => 
                c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                c.category.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();
            }
            
            if (_selectedCategory != 'الكل') {
              craftsmen = craftsmen.where((c) => c.category == _selectedCategory).toList();
            }

            if (craftsmen.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, color: Colors.grey, size: 60),
                      const SizedBox(height: 10),
                      const Text('لم يتم العثور على حرفيين'),
                      const SizedBox(height: 5),
                      Text('جرب البحث بكلمات أخرى', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCraftsmanCard(craftsmen[index]),
                childCount: craftsmen.length,
              ),
            );
          },
        ),
      ],
    );
  }

  // =============================================================================
  // CATEGORY CARD - بطاقة الفئة
  // =============================================================================
  
  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    bool isSelected = _selectedCategory == cat['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat['name']),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? cat['color'] : Colors.white,
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
            Icon(cat['icon'], color: isSelected ? Colors.white : cat['color'], size: 30),
            const SizedBox(height: 8),
            Text(
              cat['name'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // CRAFTSMAN CARD - بطاقة الحرفي
  // =============================================================================
  
  Widget _buildCraftsmanCard(Craftsman c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          // صورة الحرفي
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryColor,
            child: c.photoUrl != null
                ? ClipOval(child: Image.network(c.photoUrl!, fit: BoxFit.cover, width: 70, height: 70))
                : Text(
                    c.name.isNotEmpty ? c.name[0] : 'ح',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
          ),
          const SizedBox(width: 15),
          
          // معلومات الحرفي
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.work, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 5),
                    Text(
                      c.category,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    Text(' ${c.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 15),
                    Icon(Icons.timer, color: Colors.grey[600], size: 16),
                    Text(' ${c.experience} سنة', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.attach_money, color: secondaryColor, size: 16),
                    Text(
                      ' ${c.price} ج.م/ساعة',
                      style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.isAvailable ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c.isAvailable ? 'متاح' : 'غير متاح',
                        style: TextStyle(
                          color: c.isAvailable ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // زر التفاصيل
          IconButton(
            onPressed: () => Navigator.pushNamed(
              context, 
              '/craftsman_details',
              arguments: {
                'craftsmanId': c.uid,
                'craftsmanData': c.toMap(), // إرسال البيانات كاملة
              },
            ),
            icon: Icon(Icons.arrow_forward_ios, color: primaryColor),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // DRAWER - القائمة الجانبية
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
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF6C63FF)),
                ),
                const SizedBox(height: 10),
                Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  'مستخدم',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),
          _drawerTile(Icons.person, 'الملف الشخصي', () => Navigator.pushNamed(context, '/profile')),
          _drawerTile(Icons.category, 'جميع الفئات', () => Navigator.pushNamed(context, '/categories')),
          _drawerTile(Icons.calendar_month, 'حجوزاتي', () => Navigator.pushNamed(context, '/my_bookings')),
          _drawerTile(Icons.favorite, 'المفضلة', () => Navigator.pushNamed(context, '/favorites')),
          _drawerTile(Icons.wallet, 'المحفظة', () => Navigator.pushNamed(context, '/wallet')),
          _drawerTile(Icons.history, 'سجل الطلبات', () => Navigator.pushNamed(context, '/order_history')),
          _drawerTile(Icons.location_on, 'عناويني', () => Navigator.pushNamed(context, '/addresses')),
          _drawerTile(Icons.settings, 'الإعدادات', () => Navigator.pushNamed(context, '/settings')),
          _drawerTile(Icons.help, 'المساعدة', () => Navigator.pushNamed(context, '/help')),
          const Divider(),
          // رابط للتسجيل كحرفي
          _drawerTile(Icons.construction, 'سجل كحرفي', () => Navigator.pushNamed(context, '/craftsman_registration')),
          const Divider(),
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
  // BOTTOM NAV - شريط التنقل السفلي
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
              Navigator.pushNamed(context, '/my_bookings');
              break;
            case 2:
              Navigator.pushNamed(context, '/messages');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'المواعيد'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'الرسائل'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الحساب'),
        ],
      ),
    );
  }

  // =============================================================================
  // SIGN OUT - تسجيل الخروج
  // =============================================================================
  
  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
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