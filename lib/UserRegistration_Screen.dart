import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Home_Screen.dart'; // تأكد أن اسم الملف صحيح

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  String? _selectedCity;
  final List<String> _cities = [
    'القاهرة', 'الجيزة', 'الإسكندرية', 'الشرقية', 'الدقهلية',
    'البحيرة', 'الغربية', 'المنوفية', 'القليوبية', 'أخرى',
  ];

  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color textColor = const Color(0xFF2C3E50);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // الدالة المنقذة اللي هتخلي البرنامج ميعلقش
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      _showSnackBar('يجب الموافقة على الشروط والأحكام', Colors.red);
      return;
    }
    if (_selectedCity == null) {
      _showSnackBar('من فضلك اختر المدينة', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. إنشاء الحساب في Authentication (ده اللي يهمنا عشان الـ AuthWrapper يحس بيك)
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. رفع البيانات لـ Firestore (بدون await عشان الـ Chrome ميهنجش)
      // السطر ده هيتنفذ في الخلفية والبرنامج هيكمل عادي
      FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _selectedCity,
        'address': _addressController.text.trim(),
        'userType': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. النقل الفوري والإجباري لصفحة الـ Home
      if (mounted) {
        setState(() => _isLoading = false);
        
        _showSnackBar('تم إنشاء حسابك بنجاح! 🎉', Colors.green);

        // استخدام Navigator المباشر لكسر حلقة الـ Loading للأبد
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      String message = 'حدث خطأ أثناء التسجيل';
      if (e.code == 'email-already-in-use') {
        message = 'البريد الإلكتروني مستخدم بالفعل';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة جداً';
      }
      _showSnackBar(message, Colors.red);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar('خطأ غير متوقع: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_add, size: 80, color: Colors.white),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'الاسم الكامل', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone_outlined, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildCityDropdown(),
                      const SizedBox(height: 16),
                      _buildTextField(_addressController, 'العنوان', Icons.home_outlined, maxLines: 2),
                      const SizedBox(height: 16),
                      _buildPasswordField(_passwordController, 'كلمة المرور', _obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
                      const SizedBox(height: 16),
                      _buildPasswordField(_confirmPasswordController, 'تأكيد كلمة المرور', _obscureConfirmPassword, () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                      const SizedBox(height: 24),
                      _buildTermsCheckbox(),
                      const SizedBox(height: 30),
                      _buildRegisterButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets مساعدة ---

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: primaryColor), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
        validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: toggle),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (v) => (v == null || v.length < 6) ? '6 أحرف على الأقل' : null,
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: DropdownButtonFormField<String>(
        value: _selectedCity,
        hint: const Text('اختر المدينة'),
        items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
        onChanged: (v) => setState(() => _selectedCity = v),
        decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.location_city, color: Color(0xFF6C63FF))),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(value: _agreeToTerms, activeColor: primaryColor, onChanged: (v) => setState(() => _agreeToTerms = v ?? false)),
        const Expanded(child: Text('أوافق على الشروط والأحكام وسياسة الخصوصية')),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryColor, secondaryColor]), borderRadius: BorderRadius.circular(16)),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : const Text('إنشاء حساب', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}