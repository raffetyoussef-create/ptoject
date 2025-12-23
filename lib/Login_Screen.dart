import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import الصفحات الجديدة
import 'Home_Screen.dart'; // صفحة المستخدم
import 'craftsmen_homescreen.dart'; // صفحة الحرفيين التي قمت بإنشائها

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isCraftsmanLogin = false; // لتحديد إذا كان تسجيل دخول حرفي
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    
    _loadRememberMe();
  }
  
  Future<void> _loadRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('saved_email');
    String? savedPassword = prefs.getString('saved_password');
    bool rememberMe = prefs.getBool('remember_me') ?? false;
    
    if (rememberMe && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = rememberMe;
      });
    }
  }
  
  Future<String?> _getUserType(String userId) async {
    try {
      // أولاً: تحقق من craftsmen collection
      final craftsmanDoc = await _firestore.collection('craftsmen').doc(userId).get();
      if (craftsmanDoc.exists) {
        return 'craftsman';
      }
      
      // ثانياً: تحقق من users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['userType'] as String? ?? 'user';
      }
      
      return null;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }
  
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        // جلب نوع المستخدم
        final userType = await _getUserType(userCredential.user!.uid);
        
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', userCredential.user!.uid);
        await prefs.setString('userType', userType ?? 'user'); // حفظ نوع المستخدم
        
        if (_rememberMe) {
          await prefs.setString('saved_email', _emailController.text.trim());
          await prefs.setString('saved_password', _passwordController.text);
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
          await prefs.setBool('remember_me', false);
        }
        
        // توجيه المستخدم بناءً على نوعه
        if (mounted) {
          if (userType == 'craftsman') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const CraftsmanHomeScreen()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'حدث خطأ ما';
        
        if (e.code == 'user-not-found') {
          errorMessage = 'البريد الإلكتروني غير مسجل';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'كلمة المرور غير صحيحة';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'البريد الإلكتروني غير صالح';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'هذا الحساب معطل';
        }
        
        _showErrorSnackBar(errorMessage);
      } catch (e) {
        _showErrorSnackBar('حدث خطأ أثناء تسجيل الدخول');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _isCraftsmanLogin ? const Color(0xFF6C63FF) : const Color(0xFF1565C0);
    final gradientColors = _isCraftsmanLogin
        ? [const Color(0xFF6C63FF), const Color(0xFF2ECC71)]
        : [const Color(0xFF1565C0), const Color(0xFF1976D2), const Color(0xFF42A5F5)];
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Back button
                  Align(
                    alignment: Alignment.centerRight,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Login type toggle
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLoginTypeButton(
                            'مستخدم',
                            isSelected: !_isCraftsmanLogin,
                            onTap: () => setState(() => _isCraftsmanLogin = false),
                          ),
                          _buildLoginTypeButton(
                            'حرفي',
                            isSelected: _isCraftsmanLogin,
                            onTap: () => setState(() => _isCraftsmanLogin = true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          _isCraftsmanLogin ? 'تسجيل دخول الحرفيين' : 'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isCraftsmanLogin ? 'مرحباً بعودتك أيها الحرفي!' : 'أهلاً بعودتك!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        if (_isCraftsmanLogin) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'قم بتسجيل الدخول للوصول إلى لوحة تحكم الحرفيين',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Form card
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
                              _buildInputField(
                                controller: _emailController,
                                label: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                                primaryColor: primaryColor,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'من فضلك أدخل البريد الإلكتروني';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'البريد الإلكتروني غير صالح';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Password field
                              _buildInputField(
                                controller: _passwordController,
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline,
                                primaryColor: primaryColor,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: primaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'من فضلك أدخل كلمة المرور';
                                  }
                                  if (value.length < 6) {
                                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Remember me & Forgot password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'تذكرني',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _showForgotPasswordDialog();
                                    },
                                    child: Text(
                                      'نسيت كلمة المرور؟',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Login button
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (_isCraftsmanLogin) ...[
                                              Icon(Icons.construction, color: Colors.white),
                                              const SizedBox(width: 8),
                                            ],
                                            Text(
                                              _isCraftsmanLogin ? 'تسجيل دخول الحرفي' : 'تسجيل الدخول',
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Register links
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isCraftsmanLogin ? 'ليس لديك حساب حرفي؟' : 'ليس لديك حساب؟',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                if (_isCraftsmanLogin) {
                                  Navigator.pushNamed(context, '/craftsman_registration');
                                } else {
                                  Navigator.pushNamed(context, '/auth');
                                }
                              },
                              child: Text(
                                _isCraftsmanLogin ? 'سجل كحرفي' : 'سجل الآن',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Switch between user and craftsman registration
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCraftsmanLogin = !_isCraftsmanLogin;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isCraftsmanLogin 
                                  ? 'تسجيل دخول كـ مستخدم عادي' 
                                  : 'تسجيل دخول كـ حرفي',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoginTypeButton(String text, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textAlign: TextAlign.right,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red[400]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
  
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final primaryColor = _isCraftsmanLogin ? const Color(0xFF6C63FF) : const Color(0xFF1565C0);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'استعادة كلمة المرور',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                try {
                  await _auth.sendPasswordResetEmail(
                    email: emailController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم إرسال رابط الاستعادة إلى بريدك'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  _showErrorSnackBar('حدث خطأ، تحقق من البريد الإلكتروني');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إرسال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}