import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
            _userData?['email'] = user.email;
            _userData?['uid'] = user.uid;
          });
        } else {
          // If no data in Firestore, use basic Firebase Auth data
          setState(() {
            _userData = {
              'name': user.displayName ?? 'مستخدم',
              'email': user.email,
              'phone': user.phoneNumber ?? 'غير متوفر',
              'uid': user.uid,
            };
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }
  
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.remove('userId');
              
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF1976D2),
                    Color(0xFFF5F5F5),
                  ],
                  stops: [0.0, 0.3, 0.3],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'الملف الشخصي',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                // Navigate to edit profile
                                _showEditDialog();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Profile Avatar
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // User name
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _userData?['name'] ?? 'مستخدم',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    // User email
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _userData?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Content
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  SizedBox(height: 10),
                                  
                                  // Info section
                                  _buildSectionTitle('المعلومات الشخصية'),
                                  SizedBox(height: 16),
                                  
                                  _buildInfoCard(
                                    icon: Icons.phone_outlined,
                                    title: 'رقم الهاتف',
                                    value: _userData?['phone'] ?? 'غير متوفر',
                                    color: Color(0xFF4CAF50),
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  _buildInfoCard(
                                    icon: Icons.location_on_outlined,
                                    title: 'العنوان',
                                    value: _userData?['address'] ?? 'غير متوفر',
                                    color: Color(0xFFFF9800),
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  _buildInfoCard(
                                    icon: Icons.cake_outlined,
                                    title: 'تاريخ الميلاد',
                                    value: _userData?['birthdate'] ?? 'غير متوفر',
                                    color: Color(0xFF9C27B0),
                                  ),
                                  
                                  SizedBox(height: 30),
                                  
                                  // Actions section
                                  _buildSectionTitle('الإعدادات'),
                                  SizedBox(height: 16),
                                  
                                  _buildActionCard(
                                    icon: Icons.history_outlined,
                                    title: 'سجل الحجوزات',
                                    subtitle: 'عرض جميع حجوزاتك السابقة',
                                    color: Color(0xFF2196F3),
                                    onTap: () {
                                      // Navigate to booking history
                                    },
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  _buildActionCard(
                                    icon: Icons.favorite_outline,
                                    title: 'الحرفيون المفضلون',
                                    subtitle: 'قائمة الحرفيين المحفوظين',
                                    color: Color(0xFFE91E63),
                                    onTap: () {
                                      // Navigate to favorites
                                    },
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  _buildActionCard(
                                    icon: Icons.notifications_outlined,
                                    title: 'الإشعارات',
                                    subtitle: 'إدارة إشعارات التطبيق',
                                    color: Color(0xFFFF9800),
                                    onTap: () {
                                      // Navigate to notifications settings
                                    },
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  _buildActionCard(
                                    icon: Icons.help_outline,
                                    title: 'المساعدة والدعم',
                                    subtitle: 'تواصل معنا للمساعدة',
                                    color: Color(0xFF00BCD4),
                                    onTap: () {
                                      // Navigate to help
                                    },
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  _buildActionCard(
                                    icon: Icons.info_outline,
                                    title: 'عن التطبيق',
                                    subtitle: 'معلومات حول حِرَفي',
                                    color: Color(0xFF607D8B),
                                    onTap: () {
                                      _showAboutDialog();
                                    },
                                  ),
                                  
                                  SizedBox(height: 30),
                                  
                                  // Logout button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _logout,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.logout, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text(
                                            'تسجيل الخروج',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
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
  
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditDialog() {
    final nameController = TextEditingController(text: _userData?['name']);
    final phoneController = TextEditingController(text: _userData?['phone']);
    final addressController = TextEditingController(text: _userData?['address']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تعديل الملف الشخصي',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: addressController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                User? user = _auth.currentUser;
                if (user != null) {
                  await _firestore.collection('users').doc(user.uid).set({
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'address': addressController.text,
                  }, SetOptions(merge: true));
                  
                  await _loadUserData();
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تحديث البيانات بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ أثناء التحديث'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1565C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF1565C0),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.handyman_rounded, color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              'حِرَفي',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الإصدار 1.0.0',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Text(
              'تطبيق حِرَفي يربط الحرفيين المحترفين بالعملاء بطريقة سهلة وسريعة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}