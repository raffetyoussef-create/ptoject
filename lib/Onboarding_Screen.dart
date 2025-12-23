import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ألوان عصرية
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color accentColor = const Color(0xFFFF6B6B);
  final Color warningColor = const Color(0xFFFFA502);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color textColor = const Color(0xFF2C3E50);

  final List<OnboardingPage> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      OnboardingPage(
        title: 'مرحباً بك في حرفي',
        description: 'المنصة الأولى للتواصل مع أفضل الحرفيين والمهنيين في مصر',
        icon: Icons.waving_hand,
        color: const Color(0xFF6C63FF),
        lottieAnimation: '🎨',
      ),
      OnboardingPage(
        title: 'ابحث عن حرفيين محترفين',
        description: 'اعثر على الحرفي المناسب لاحتياجاتك من بين مئات الحرفيين المتخصصين',
        icon: Icons.search,
        color: const Color(0xFF2ECC71),
        lottieAnimation: '🔍',
      ),
      OnboardingPage(
        title: 'احجز بسهولة وأمان',
        description: 'احجز موعدك واحصل على الخدمة في الوقت المناسب مع ضمان الجودة',
        icon: Icons.calendar_today,
        color: const Color(0xFFFFA502),
        lottieAnimation: '📅',
      ),
      OnboardingPage(
        title: 'قيم وشارك تجربتك',
        description: 'ساعد الآخرين باختيار الأفضل من خلال تقييماتك وآرائك',
        icon: Icons.star,
        color: const Color(0xFFFF6B6B),
        lottieAnimation: '⭐',
      ),
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // زر التخطي
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // شعار التطبيق
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.construction,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'حرفي',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  
                  // زر التخطي
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _pages.length - 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // محتوى الصفحات
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // المؤشرات والأزرار
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  // نقاط المؤشر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[index].color
                              : textColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // الأزرار
                  Row(
                    children: [
                      // زر الرجوع
                      if (_currentPage > 0)
                        Container(
                          width: 56,
                          height: 56,
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
                          child: IconButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: textColor,
                            ),
                          ),
                        ),
                      
                      if (_currentPage > 0) const SizedBox(width: 16),
                      
                      // زر التالي/البدء
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _pages[_currentPage].color,
                                _pages[_currentPage].color.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_currentPage].color.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage == _pages.length - 1) {
                                _completeOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'ابدأ الآن'
                                      : 'التالي',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // الرسوم المتحركة / الأيقونة
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        page.color,
                        page.color.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: page.color.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      page.lottieAnimation,
                      style: const TextStyle(fontSize: 100),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 60),
          
          // العنوان
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Text(
                    page.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // الوصف
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Text(
                    page.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 40),
          
          // ميزات إضافية للصفحة الأولى
          if (_currentPage == 0)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      _buildFeatureChip(Icons.verified, 'حرفيون موثوقون', secondaryColor),
                      const SizedBox(height: 12),
                      _buildFeatureChip(Icons.security, 'دفع آمن', primaryColor),
                      const SizedBox(height: 12),
                      _buildFeatureChip(Icons.support_agent, 'دعم 24/7', warningColor),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String lottieAnimation;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.lottieAnimation,
  });
}