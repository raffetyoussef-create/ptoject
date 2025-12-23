import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class EditCraftsmanProfileScreen extends StatefulWidget {
  const EditCraftsmanProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditCraftsmanProfileScreen> createState() => _EditCraftsmanProfileScreenState();
}

class _EditCraftsmanProfileScreenState extends State<EditCraftsmanProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isSaving = false;
  
  final List<String> _categories = [
    'كهربائي', 'سباك', 'نجار', 'دهان', 'حداد',
    'بناء', 'تكييف وتبريد', 'نقاش', 'سيراميك', 'ألومنيوم',
  ];
  
  List<String> _selectedServices = [];
  final List<String> _availableServices = [
    'صيانة دورية', 'تركيبات جديدة', 'إصلاح أعطال', 'معاينة واستشارة', 'تجديد شامل', 'فحص أمان',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _loadCraftsmanData();
  }
  
  Future<void> _loadCraftsmanData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('craftsmen').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _addressController.text = data['address'] ?? '';
            _experienceController.text = data['experience']?.toString() ?? '';
            _bioController.text = data['bio'] ?? '';
            _priceController.text = data['hourlyRate']?.toString() ?? '';
            _selectedCategory = data['category'];
            _selectedServices = List<String>.from(data['services'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }
  
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        _showSnackBar('من فضلك اختر الحرفة الأساسية', Colors.orange);
        return;
      }
      
      setState(() => _isSaving = true);
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('craftsmen').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'experience': int.tryParse(_experienceController.text) ?? 0,
            'bio': _bioController.text.trim(),
            'hourlyRate': double.tryParse(_priceController.text) ?? 0.0,
            'category': _selectedCategory,
            'services': _selectedServices,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          _showSnackBar('تم تحديث ملفك الشخصي بنجاح ✨', Colors.green);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } catch (e) {
        _showSnackBar('حدث خطأ أثناء الحفظ، يرجى المحاولة لاحقاً', Colors.red);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: _isLoading ? _buildLoadingOverlay() : _buildMainContent(),
    );
  }

  Widget _buildLoadingOverlay() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
      ),
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        // الخلفية المتدرجة العلوية
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFFF6F00), Color(0xFFFF9100)],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFormCard(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'تعديل الملف المهني',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 48), // لموازنة زر الرجوع
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(Icons.badge_outlined, 'المعلومات الشخصية'),
                const SizedBox(height: 20),
                _buildTextField(_nameController, 'الاسم كما يظهر للعملاء', Icons.person_outline),
                const SizedBox(height: 15),
                _buildTextField(_phoneController, 'رقم التواصل المباشر', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 15),
                _buildTextField(_addressController, 'المنطقة أو الحي', Icons.map_outlined),
                
                const SizedBox(height: 35),
                _buildSectionHeader(Icons.work_history_outlined, 'الخبرة والأسعار'),
                const SizedBox(height: 20),
                _buildCategoryDropdown(),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_experienceController, 'سنوات الخبرة', Icons.history, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_priceController, 'السعر / ساعة', Icons.payments_outlined, keyboardType: TextInputType.number)),
                  ],
                ),
                
                const SizedBox(height: 35),
                _buildSectionHeader(Icons.auto_awesome_outlined, 'الخدمات التي تتقنها'),
                const SizedBox(height: 15),
                _buildServicesWrap(),
                
                const SizedBox(height: 35),
                _buildSectionHeader(Icons.description_outlined, 'نبذة مهنية (Bio)'),
                const SizedBox(height: 15),
                _buildBioField(),
                
                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF6F00), size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6F00), size: 22),
        filled: true,
        fillColor: const Color(0xFFFDFDFD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFFF6F00), width: 1.5)),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory,
          hint: const Text('اختر حرفتك الأساسية', textAlign: TextAlign.right),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, textAlign: TextAlign.right))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
      ),
    );
  }

  Widget _buildServicesWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableServices.map((service) {
        bool isSelected = _selectedServices.contains(service);
        return FilterChip(
          label: Text(service),
          selected: isSelected,
          onSelected: (val) {
            setState(() {
              val ? _selectedServices.add(service) : _selectedServices.remove(service);
            });
          },
          selectedColor: const Color(0xFFFF6F00).withOpacity(0.2),
          checkmarkColor: const Color(0xFFFF6F00),
          labelStyle: TextStyle(color: isSelected ? const Color(0xFFFF6F00) : Colors.black54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? const Color(0xFFFF6F00) : Colors.grey[300]!)),
        );
      }).toList(),
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      maxLines: 4,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: 'مثلاً: متخصص في صيانة التكييف المركزي بخبرة تزيد عن 10 سنوات...',
        filled: true,
        fillColor: const Color(0xFFFDFDFD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6F00),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 5,
          shadowColor: const Color(0xFFFF6F00).withOpacity(0.4),
        ),
        child: _isSaving
            ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('حفظ التعديلات وتحديث الملف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}