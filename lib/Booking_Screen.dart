import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:intl/intl.dart' as intl;

class BookingScreen extends StatefulWidget {
  // استقبال البيانات بشكل صحيح من arguments
  final String? craftsmanId;
  final String? craftsmanName;
  final String? craftsmanCategory;

  const BookingScreen({
    Key? key,
    this.craftsmanId,
    this.craftsmanName,
    this.craftsmanCategory,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();

  // ✅ إضافة PageController للتحكم في التنقل بين الصفحات
  final PageController _pageController = PageController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _currentStep = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _craftsmanData;

  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color accentColor = const Color(0xFFFF6B6B);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  final List<String> _services = [
    'صيانة منزلية عامة',
    'تركيب وتأسيس جديد',
    'إصلاح أعطال طارئة',
    'استشارة فنية ومعاينة',
    'خدمة دورية وقائية',
  ];
  String? _selectedService;

  @override
  void initState() {
    super.initState();
    _loadCraftsmanData();
  }

  // تحميل بيانات الحرفي من Firestore
  Future<void> _loadCraftsmanData() async {
    if (widget.craftsmanId == null) {
      _showSnackBar('خطأ: لم يتم تحديد الحرفي', isError: true);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('craftsmen')
          .doc(widget.craftsmanId)
          .get();

      if (doc.exists) {
        setState(() {
          _craftsmanData = doc.data();
          // تعبئة السعر تلقائياً
          _priceController.text = _craftsmanData?['price']?.toString() ?? '0';
        });
      }
    } catch (e) {
      _showSnackBar('خطأ في تحميل بيانات الحرفي', isError: true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _pageController.dispose(); // ✅ تنظيف الـ controller
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      _showSnackBar('الرجاء تحديد التاريخ والوقت للزيارة', isError: true);
      return;
    }
    if (_selectedService == null) {
      _showSnackBar('الرجاء اختيار نوع الخدمة', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final bookingData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'serviceType': _selectedService,
        'location': _addressController.text.trim(),
        'expectedPrice': double.tryParse(_priceController.text) ?? 0,
        'appointmentDate': Timestamp.fromDate(_selectedDate!),
        'appointmentTime': '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'craftsmanId': widget.craftsmanId,
        'craftsmanName': widget.craftsmanName ?? _craftsmanData?['name'] ?? 'غير معروف',
        'craftsmanCategory': widget.craftsmanCategory ?? _craftsmanData?['category'] ?? 'عام',
        'customerId': user.uid,
        'customerName': userDoc.data()?['name'] ?? 'عميل حِرَفي',
        'customerPhone': userDoc.data()?['phone'] ?? '',
        'status': 'new', // ✅ وضع الحالة "new" لتظهر كطلب جديد
        'createdAt': FieldValue.serverTimestamp(),
      }; // ✅ إغلاق الـ Map بشكل صحيح

      // حفظ في مجموعة bookings كما طلب المستخدم
      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('عذراً، حدث خطأ: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من وجود البيانات
    if (widget.craftsmanId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: accentColor),
              const SizedBox(height: 20),
              const Text('خطأ: لم يتم تحديد الحرفي بشكل صحيح'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildBackgroundDecoration(),
          SafeArea(
            child: Column(
              children: [
                _buildModernHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController, // ✅ ربط الـ PageController
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStepContainer(_buildServiceDetailsStep()),
                        _buildStepContainer(_buildLocationTimeStep()),
                        _buildStepContainer(_buildReviewStep()),
                      ],
                    ),
                  ),
                ),
                _buildNavigationActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  Widget _buildServiceDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionTitle('وصف الخدمة المطلوبة', 'أخبرنا ماذا تريد من ${widget.craftsmanName ?? 'الحرفي'} أن يفعل'),
        const SizedBox(height: 30),
        _buildStyledTextField(
          controller: _titleController,
          label: 'عنوان الطلب (مثال: تسريب مياه بالمطبخ)',
          icon: Icons.edit_note_rounded,
          validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال عنوان مختصر للطلب' : null,
        ),
        const SizedBox(height: 20),
        _buildDropdownField(),
        const SizedBox(height: 20),
        _buildStyledTextField(
          controller: _descriptionController,
          label: 'تفاصيل المشكلة... (كلما كنت دقيقاً ساعدت الحرفي)',
          icon: Icons.description_outlined,
          maxLines: 4,
          validator: (v) => (v == null || v.length < 10) ? 'يرجى كتابة وصف أكثر تفصيلاً' : null,
        ),
      ],
    );
  }

  Widget _buildLocationTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionTitle('الموعد والمكان', 'حدد الوقت والموقع المناسبين للزيارة'),
        const SizedBox(height: 30),
        _buildPickerTile(
          label: 'تاريخ الزيارة',
          value: _selectedDate == null ? null : intl.DateFormat('yyyy/MM/dd', 'ar').format(_selectedDate!),
          icon: Icons.calendar_month_rounded,
          onTap: _pickDate,
        ),
        const SizedBox(height: 20),
        _buildPickerTile(
          label: 'وقت الوصول التقريبي',
          value: _selectedTime?.format(context),
          icon: Icons.access_time_rounded,
          onTap: _pickTime,
        ),
        const SizedBox(height: 20),
        _buildStyledTextField(
          controller: _addressController,
          label: 'عنوان المنزل بالتفصيل',
          icon: Icons.location_on_rounded,
          maxLines: 2,
          validator: (v) => (v == null || v.isEmpty) ? 'العنوان ضروري لوصول الحرفي إليك' : null,
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionTitle('المراجعة النهائية', 'راجع بياناتك قبل إرسال الطلب النهائي'),
        const SizedBox(height: 25),
        _buildReviewTicket(),
        const SizedBox(height: 25),
        _buildStyledTextField(
          controller: _priceController,
          label: 'ميزانية تقريبية',
          icon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
          suffixText: 'ج.م',
        ),
        const SizedBox(height: 20),
        _buildNoticeBox(),
      ],
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBlurCircleButton(Icons.close, () => Navigator.pop(context)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('حجز خدمة جديدة', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                widget.craftsmanName ?? 'حرفي',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
      child: Row(
        children: List.generate(3, (index) {
          bool isActive = _currentStep == index;
          bool isDone = _currentStep > index;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: isDone ? secondaryColor : (isActive ? primaryColor : Colors.white),
                    shape: BoxShape.circle,
                    boxShadow: isActive ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10)] : [],
                    border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep > index ? secondaryColor : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? suffixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor, size: 22),
          suffixText: suffixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedService,
        items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s, textAlign: TextAlign.right))).toList(),
        onChanged: (v) => setState(() => _selectedService = v),
        validator: (v) => v == null ? 'يرجى اختيار نوع الخدمة' : null,
        decoration: InputDecoration(
          labelText: 'نوع الخدمة',
          prefixIcon: Icon(Icons.category_rounded, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(Icons.chevron_left, color: Colors.grey.shade400),
            const Spacer(),
            Text(
              value ?? label,
              style: TextStyle(
                color: value == null ? Colors.grey : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 15),
            Icon(icon, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTicket() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.craftsmanCategory ?? _craftsmanData?['category'] ?? 'عام',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.craftsmanName ?? _craftsmanData?['name'] ?? 'حرفي',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildReviewRow('الخدمة', _titleController.text.isEmpty ? '-' : _titleController.text),
                _buildReviewRow('النوع', _selectedService ?? 'غير محدد'),
                const Divider(height: 30),
                _buildReviewRow(
                  'الموعد',
                  _selectedDate == null ? '-' : intl.DateFormat('dd MMMM, yyyy', 'ar').format(_selectedDate!),
                ),
                _buildReviewRow('التوقيت', _selectedTime?.format(context) ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              val,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.left,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationActions() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() => _currentStep--);
                  _pageController.animateToPage(
                    _currentStep,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('السابق', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_currentStep < 2 ? _nextStep : _submitBooking),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.all(18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 5,
                shadowColor: primaryColor.withOpacity(0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      _currentStep < 2 ? 'التالي' : 'إتمام الحجز',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    // في الخطوة الأولى، نتحقق فقط من الحقول النصية والقائمة المنسدلة
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate() || _selectedService == null) return;
    }
    
    // في الخطوة الثانية، نتحقق من اختيار الوقت والتاريخ
    if (_currentStep == 1) {
      if (_selectedDate == null || _selectedTime == null) {
        _showSnackBar('الرجاء تحديد التاريخ والوقت أولاً', isError: true);
        return;
      }
    }

    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 90),
              const SizedBox(height: 25),
              const Text(
                'تم الحجز بنجاح!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'سيتواصل معك ${widget.craftsmanName ?? 'الحرفي'} قريباً لتأكيد الموعد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    'حسناً، عودة',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlurCircleButton(IconData icon, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.2),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeBox() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'سيقوم الحرفي بمراجعة الطلب والموافقة عليه أو التواصل معك للتعديل.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned(
      top: -100,
      right: -100,
      child: CircleAvatar(
        radius: 150,
        backgroundColor: primaryColor.withOpacity(0.05),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          sub,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      ],
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right),
        backgroundColor: isError ? accentColor : secondaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}