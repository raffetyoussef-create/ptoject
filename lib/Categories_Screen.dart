import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // ألوان بريميوم للتطبيق
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color accentColor = const Color(0xFFFF6B6B);
  final Color warningColor = const Color(0xFFFFA502);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color darkColor = const Color(0xFF2C3E50);

  // قائمة الفئات الموسعة مع بيانات إضافية
  final List<Map<String, dynamic>> _allCategories = [
    {
      'name': 'نجار',
      'icon': Icons.carpenter,
      'color': const Color(0xFF6C63FF),
      'description': 'أعمال النجارة، صيانة الأثاث، وتركيب المطابخ والأبواب.',
      'tip': 'نصيحة: تأكد من نوع الخشب المستخدم قبل البدء.'
    },
    {
      'name': 'سباك',
      'icon': Icons.plumbing,
      'color': const Color(0xFF2ECC71),
      'description': 'تأسيس وصيانة السباكة، كشف التسريبات، وتركيب الأدوات الصحية.',
      'tip': 'نصيحة: افحص المحابس الرئيسية دورياً لتجنب الغرق.'
    },
    {
      'name': 'كهربائي',
      'icon': Icons.electrical_services,
      'color': const Color(0xFFFF6B6B),
      'description': 'تأسيس الكهرباء، إصلاح الأعطال، وتركيب النجف والإضاءة الحديثة.',
      'tip': 'نصيحة: استخدم أسلاكاً معتمدة لضمان سلامة منزلك.'
    },
    {
      'name': 'دهان',
      'icon': Icons.format_paint,
      'color': const Color(0xFFFFA502),
      'description': 'دهانات الحوائط، ورق الحائط، وديكورات الجبس بورد الحديثة.',
      'tip': 'نصيحة: جرب عينة اللون على الحائط قبل البدء بالكامل.'
    },
    {
      'name': 'مكيفات',
      'icon': Icons.ac_unit,
      'color': const Color(0xFF3498DB),
      'description': 'تركيب المكيفات بجميع أنواعها، شحن الفريون، والتنظيف الدوري.',
      'tip': 'نصيحة: نظف الفلاتر كل أسبوعين لزيادة كفاءة التبريد.'
    },
    {
      'name': 'سيراميك',
      'icon': Icons.grid_4x4,
      'color': const Color(0xFF9B59B6),
      'description': 'تركيب السيراميك، البورسلين، الرخام، وجلي البلاط القديم.',
      'tip': 'نصيحة: اترك مسافات تمدد كافية بين البلاطات.'
    },
    {
      'name': 'حداد',
      'icon': Icons.handyman,
      'color': const Color(0xFF34495E),
      'description': 'أعمال الكريتال، تركيب المظلات، وصيانة الأبواب الحديدية والشبابيك.',
      'tip': 'نصيحة: ادهن الحديد بمادة مضادة للصدأ فور التركيب.'
    },
    {
      'name': 'نقاش',
      'icon': Icons.architecture,
      'color': const Color(0xFFE74C3C),
      'description': 'أعمال المحارة، تشطيبات الواجهات، وعزل الرطوبة والحرارة.',
      'tip': 'نصيحة: عالج الرطوبة أولاً قبل البدء بأي أعمال نقاشة.'
    },
    {
      'name': 'زجاج',
      'icon': Icons.window,
      'color': const Color(0xFF1ABC9C),
      'description': 'تركيب واجهات الزجاج، المرايا الديكورية، وزجاج السيكوريت.',
      'tip': 'نصيحة: الزجاج المدبل (Double Glass) يوفر في استهلاك الكهرباء.'
    },
    {
      'name': 'تنظيف',
      'icon': Icons.cleaning_services,
      'color': const Color(0xFF16A085),
      'description': 'تنظيف شامل للمنازل، غسيل السجاد والستائر، وتعقيم الأسطح.',
      'tip': 'نصيحة: استخدم مواد تنظيف صديقة للبيئة.'
    },
    {
      'name': 'حدائق',
      'icon': Icons.yard,
      'color': const Color(0xFF27AE60),
      'description': 'تنسيق الحدائق، تركيب النجيل الصناعي، وصيانة شبكات الري.',
      'tip': 'نصيحة: الري في الصباح الباكر يقلل من تبخر المياه.'
    },
    {
      'name': 'أخرى',
      'icon': Icons.more_horiz,
      'color': const Color(0xFF95A5A6),
      'description': 'هل تحتاج خدمة غير موجودة؟ ابحث هنا عن خدمات متنوعة.',
      'tip': 'نصيحة: لا تتردد في طلب استشارة فنية قبل أي مشروع.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildHeroBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeaderContent(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllCategoriesGrid(),
                      _buildFavoritesListView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // خلفية ملونة في الأعلى لإعطاء مظهر عصري
  Widget _buildHeroBackground() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBlurButton(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
              const Text(
                'اكتشف الخدمات',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              _buildBlurButton(Icons.help_outline, () {}),
            ],
          ),
          const SizedBox(height: 25),
          _buildSearchField(),
          const SizedBox(height: 20),
          _buildCustomTabBar(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'ابحث عن فئة (مثلاً: نجار)...',
          prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(15)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        labelColor: primaryColor,
        unselectedLabelColor: Colors.white70,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: 'جميع الخدمات'), Tab(text: 'المفضلة')],
      ),
    );
  }

  Widget _buildAllCategoriesGrid() {
    final filteredCategories = _allCategories.where((c) {
      return c['name'].contains(_searchQuery) || c['description'].contains(_searchQuery);
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildStatsSliver(),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildCategoryCard(filteredCategories[i]),
              childCount: filteredCategories.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('craftsmen')
          .where('category', isEqualTo: cat['name'])
          .where('isAvailable', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        int activeCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return InkWell(
          onTap: () => Navigator.pushNamed(context, '/craftsman_list', arguments: cat['name']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: cat['color'].withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                _buildCardHeader(cat),
                _buildCardBody(cat, activeCount),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardHeader(Map<String, dynamic> cat) {
    return Container(
      height: 90, width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cat['color'], cat['color'].withOpacity(0.7)]),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      child: Stack(
        children: [
          Positioned(right: -10, top: -10, child: Icon(cat['icon'], size: 80, color: Colors.white10)),
          Center(child: CircleAvatar(backgroundColor: Colors.white24, radius: 30, child: Icon(cat['icon'], color: Colors.white, size: 30))),
          Positioned(top: 5, left: 5, child: _buildFavoriteIcon(cat['name'])),
        ],
      ),
    );
  }

  Widget _buildCardBody(Map<String, dynamic> cat, int count) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text('${count > 0 ? "متوفر حالياً: $count" : "جاري توفير فنيين"}',
              style: TextStyle(color: count > 0 ? secondaryColor : Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFavoritesListView() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('favorite_categories').where('userId', isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();
        
        var favoriteNames = snapshot.data!.docs.map((doc) => doc['categoryName']).toList();
        var favCats = _allCategories.where((c) => favoriteNames.contains(c['name'])).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: favCats.length,
          itemBuilder: (context, i) => _buildWideCategoryCard(favCats[i]),
        );
      },
    );
  }

  Widget _buildWideCategoryCard(Map<String, dynamic> cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: cat['color'].withOpacity(0.1), child: Icon(cat['icon'], color: cat['color'])),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(cat['description'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.favorite, color: Colors.red), onPressed: () => _toggleFavorite(cat['name'])),
        ],
      ),
    );
  }

  // --- Logic Functions ---

  Future<void> _toggleFavorite(String categoryName) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    var query = await FirebaseFirestore.instance.collection('favorite_categories')
        .where('userId', isEqualTo: userId).where('categoryName', isEqualTo: categoryName).get();

    if (query.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('favorite_categories').add({
        'userId': userId, 'categoryName': categoryName, 'createdAt': FieldValue.serverTimestamp(),
      });
      _showSnack('تمت إضافة $categoryName للمفضلة', secondaryColor);
    } else {
      await query.docs.first.reference.delete();
      _showSnack('تمت الإزالة من المفضلة', accentColor);
    }
  }

  // --- Utility Widgets ---

  Widget _buildFavoriteIcon(String name) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('favorite_categories')
          .where('userId', isEqualTo: userId).where('categoryName', isEqualTo: name).snapshots(),
      builder: (context, snapshot) {
        bool isFav = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return IconButton(
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.white),
          onPressed: () => _toggleFavorite(name),
        );
      },
    );
  }

  Widget _buildBlurButton(IconData icon, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white24,
          child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap),
        ),
      ),
    );
  }

  Widget _buildStatsSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            _buildMiniStat('فئة مسجلة', _allCategories.length.toString(), primaryColor),
            const SizedBox(width: 10),
            _buildMiniStat('فني متاح', '120+', secondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
          Icon(Icons.heart_broken_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const Text('قائمة المفضلة فارغة حالياً', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }
}