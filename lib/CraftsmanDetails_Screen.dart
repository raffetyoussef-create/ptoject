import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CraftsmanDetailsScreen extends StatefulWidget {
  final String craftsmanId;
  
  const CraftsmanDetailsScreen({Key? key, required this.craftsmanId}) : super(key: key);

  @override
  State<CraftsmanDetailsScreen> createState() => _CraftsmanDetailsScreenState();
}

class _CraftsmanDetailsScreenState extends State<CraftsmanDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

  // ألوان عصرية
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color accentColor = const Color(0xFFFF6B6B);
  final Color warningColor = const Color(0xFFFFA502);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkFavorite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('craftsmanId', isEqualTo: widget.craftsmanId)
        .get();

    if (mounted) {
      setState(() => _isFavorite = doc.docs.isNotEmpty);
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_isFavorite) {
      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('craftsmanId', isEqualTo: widget.craftsmanId)
          .get();
      
      for (var d in doc.docs) {
        await d.reference.delete();
      }
    } else {
      await FirebaseFirestore.instance.collection('favorites').add({
        'userId': userId,
        'craftsmanId': widget.craftsmanId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('craftsmen')
            .doc(widget.craftsmanId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: accentColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لم يتم العثور على الحرفي',
                    style: TextStyle(
                      fontSize: 18,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          return CustomScrollView(
            slivers: [
              // صورة الغلاف والمعلومات الأساسية
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: primaryColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_ios, color: primaryColor, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // صورة الخلفية
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: data['imageUrl'] != null
                            ? Image.network(
                                data['imageUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 100,
                                    color: Colors.white.withOpacity(0.5),
                                  );
                                },
                              )
                            : Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.white.withOpacity(0.5),
                              ),
                      ),
                      
                      // تدرج شفاف
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      
                      // المعلومات الأساسية
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['name'] ?? 'غير معروف',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (data['isVerified'] ?? false)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: secondaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    data['category'] ?? 'عام',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.location_on, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  data['location'] ?? 'القاهرة',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // الإحصائيات
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.star,
                        data['rating']?.toStringAsFixed(1) ?? '4.5',
                        'التقييم',
                        warningColor,
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        Icons.work,
                        '${data['completedJobs'] ?? 0}',
                        'مشروع',
                        secondaryColor,
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        Icons.timer,
                        '${data['experience'] ?? 5} سنوات',
                        'الخبرة',
                        primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tab Bar
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: textColor.withOpacity(0.6),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'نبذة'),
                      Tab(text: 'الأعمال'),
                      Tab(text: 'التقييمات'),
                    ],
                  ),
                ),
              ),
              
              // محتوى التبويبات
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(data),
                    _buildPortfolioTab(),
                    _buildReviewsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      
      // زر الحجز
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('craftsmen')
                    .doc(widget.craftsmanId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السعر',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${data['price'] ?? 100} ج.م/ساعة',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/booking',
                      arguments: widget.craftsmanId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'احجز الآن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: textColor.withOpacity(0.1),
    );
  }

  Widget _buildAboutTab(Map<String, dynamic> data) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // الوصف
        _buildSectionCard(
          'نبذة عني',
          Icons.info_outline,
          primaryColor,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['description'] ?? 'لا يوجد وصف متاح',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // المهارات
        _buildSectionCard(
          'المهارات',
          Icons.star_outline,
          secondaryColor,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (data['skills'] as List<dynamic>? ?? [])
                .map((skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: secondaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        skill.toString(),
                        style: TextStyle(
                          color: secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ساعات العمل
        _buildSectionCard(
          'ساعات العمل',
          Icons.access_time,
          warningColor,
          Column(
            children: [
              _buildWorkingHourRow('السبت - الخميس', data['workingHours']?['weekdays'] ?? '9:00 ص - 6:00 م'),
              const SizedBox(height: 8),
              _buildWorkingHourRow('الجمعة', data['workingHours']?['friday'] ?? 'إجازة'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // معلومات الاتصال
        _buildSectionCard(
          'معلومات الاتصال',
          Icons.contact_phone,
          accentColor,
          Column(
            children: [
              _buildContactRow(Icons.phone, data['phone'] ?? 'غير متاح'),
              const SizedBox(height: 12),
              _buildContactRow(Icons.email, data['email'] ?? 'غير متاح'),
              const SizedBox(height: 12),
              _buildContactRow(Icons.location_on, data['address'] ?? 'غير متاح'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('portfolio')
          .where('craftsmanId', isEqualTo: widget.craftsmanId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 80,
                  color: textColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أعمال سابقة',
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var work = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _buildPortfolioCard(work);
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('craftsmanId', isEqualTo: widget.craftsmanId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 80,
                  color: textColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد تقييمات بعد',
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var review = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _buildReviewCard(review);
          },
        );
      },
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildWorkingHourRow(String day, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 15,
            color: textColor.withOpacity(0.7),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioCard(Map<String, dynamic> work) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: work['imageUrl'] != null
                  ? Image.network(
                      work['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: primaryColor.withOpacity(0.5),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: primaryColor.withOpacity(0.5),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work['title'] ?? 'عمل سابق',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  work['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] ?? 'مستخدم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < (review['rating'] ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          color: warningColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['comment'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }}