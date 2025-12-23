import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CraftsmanListScreen extends StatefulWidget {
  final String? categoryName;
  
  const CraftsmanListScreen({Key? key, this.categoryName}) : super(key: key);

  @override
  State<CraftsmanListScreen> createState() => _CraftsmanListScreenState();
}

class _CraftsmanListScreenState extends State<CraftsmanListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'rating'; // rating, price, experience
  bool _showAvailableOnly = true;
  double _maxPrice = 500;
  double _minRating = 0;

  // ألوان عصرية
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color accentColor = const Color(0xFFFF6B6B);
  final Color warningColor = const Color(0xFFFFA502);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF2C3E50);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header مع البحث والفلترة
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // العنوان وزر الرجوع
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.categoryName ?? 'جميع الحرفيين',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list, color: Colors.white),
                        onPressed: _showFilterSheet,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // شريط البحث
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو المنطقة...',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: accentColor),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // أزرار الترتيب السريع
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickFilterChip(
                          'الأعلى تقييماً',
                          Icons.star,
                          _sortBy == 'rating',
                          () => setState(() => _sortBy = 'rating'),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip(
                          'الأقل سعراً',
                          Icons.attach_money,
                          _sortBy == 'price',
                          () => setState(() => _sortBy = 'price'),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip(
                          'الأكثر خبرة',
                          Icons.work,
                          _sortBy == 'experience',
                          () => setState(() => _sortBy = 'experience'),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip(
                          'متاح فقط',
                          Icons.check_circle,
                          _showAvailableOnly,
                          () => setState(() => _showAvailableOnly = !_showAvailableOnly),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // قائمة الحرفيين
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'جاري التحميل...',
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
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
                            'حدث خطأ في تحميل البيانات',
                            style: TextStyle(
                              fontSize: 18,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 80,
                            color: textColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا يوجد حرفيون متاحون',
                            style: TextStyle(
                              fontSize: 18,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'جرب تغيير الفلاتر أو البحث',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var craftsmen = snapshot.data!.docs;
                  
                  // تطبيق البحث المحلي
                  if (_searchQuery.isNotEmpty) {
                    craftsmen = craftsmen.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      var name = data['name']?.toString().toLowerCase() ?? '';
                      var location = data['location']?.toString().toLowerCase() ?? '';
                      var query = _searchQuery.toLowerCase();
                      return name.contains(query) || location.contains(query);
                    }).toList();
                  }
                  
                  // تطبيق فلتر التقييم والسعر
                  craftsmen = craftsmen.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    var rating = data['rating']?.toDouble() ?? 0.0;
                    var price = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
                    return rating >= _minRating && price <= _maxPrice;
                  }).toList();
                  
                  // الترتيب
                  craftsmen.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;
                    
                    if (_sortBy == 'rating') {
                      var ratingA = dataA['rating']?.toDouble() ?? 0.0;
                      var ratingB = dataB['rating']?.toDouble() ?? 0.0;
                      return ratingB.compareTo(ratingA);
                    } else if (_sortBy == 'price') {
                      var priceA = double.tryParse(dataA['price']?.toString() ?? '0') ?? 0.0;
                      var priceB = double.tryParse(dataB['price']?.toString() ?? '0') ?? 0.0;
                      return priceA.compareTo(priceB);
                    } else if (_sortBy == 'experience') {
                      var expA = int.tryParse(dataA['experience']?.toString() ?? '0') ?? 0;
                      var expB = int.tryParse(dataB['experience']?.toString() ?? '0') ?? 0;
                      return expB.compareTo(expA);
                    }
                    return 0;
                  });

                  return Column(
                    children: [
                      // عدد النتائج
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'تم العثور على ${craftsmen.length} حرفي',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // القائمة
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: craftsmen.length,
                          itemBuilder: (context, index) {
                            var data = craftsmen[index].data() as Map<String, dynamic>;
                            return _buildCraftsmanCard(
                              craftsmanId: craftsmen[index].id,
                              name: data['name'] ?? 'غير معروف',
                              category: data['category'] ?? 'عام',
                              rating: data['rating']?.toDouble() ?? 4.5,
                              price: data['price']?.toString() ?? '100',
                              imageUrl: data['imageUrl'],
                              experience: data['experience']?.toString() ?? '5',
                              location: data['location'] ?? 'القاهرة',
                              isAvailable: data['isAvailable'] ?? true,
                              completedJobs: data['completedJobs'] ?? 0,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('craftsmen');
    
    if (widget.categoryName != null) {
      query = query.where('category', isEqualTo: widget.categoryName);
    }
    
    if (_showAvailableOnly) {
      query = query.where('isAvailable', isEqualTo: true);
    }
    
    return query.snapshots();
  }

  Widget _buildQuickFilterChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? primaryColor : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCraftsmanCard({
    required String craftsmanId,
    required String name,
    required String category,
    required double rating,
    required String price,
    String? imageUrl,
    required String experience,
    required String location,
    required bool isAvailable,
    required int completedJobs,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/craftsman_details',
              arguments: craftsmanId,
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // صورة الحرفي
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.white,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        
                        // حالة التوفر
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isAvailable ? secondaryColor : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const SizedBox(width: 8, height: 8),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // معلومات الحرفي
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.verified,
                                color: secondaryColor,
                                size: 20,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 6),
                          
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: accentColor,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Icon(Icons.star, color: warningColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '($completedJobs)',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.work_outline,
                                size: 14,
                                color: textColor.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$experience سنوات',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // الأزرار السفلية
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: secondaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$price ج.م/ساعة',
                              style: TextStyle(
                                color: secondaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: primaryColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // المؤشر
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'الفلاتر والترتيب',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // فلتر السعر
              Text(
                'السعر الأقصى: ${_maxPrice.toInt()} ج.م',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Slider(
                value: _maxPrice,
                min: 50,
                max: 500,
                divisions: 45,
                activeColor: primaryColor,
                inactiveColor: primaryColor.withOpacity(0.2),
                onChanged: (value) {
                  setModalState(() => _maxPrice = value);
                },
              ),
              
              const SizedBox(height: 16),
              
              // فلتر التقييم
              Text(
                'التقييم الأدنى: ${_minRating.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Slider(
                value: _minRating,
                min: 0,
                max: 5,
                divisions: 10,
                activeColor: warningColor,
                inactiveColor: warningColor.withOpacity(0.2),
                onChanged: (value) {
                  setModalState(() => _minRating = value);
                },
              ),
              
              const SizedBox(height: 24),
              
              // زر التطبيق
              Container(
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
                    setState(() {});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'تطبيق الفلاتر',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // زر إعادة التعيين
              TextButton(
                onPressed: () {
                  setModalState(() {
                    _maxPrice = 500;
                    _minRating = 0;
                  });
                  setState(() {});
                },
                child: Text(
                  'إعادة تعيين',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}