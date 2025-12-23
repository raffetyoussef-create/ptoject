import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'craftsmen_homescreen.dart';
import 'firebase_options.dart';

// Import all screens
import 'Splash_Screen.dart';
import 'Onboarding_Screen.dart';
import 'auth_screen.dart';
import 'Login_Screen.dart';

import 'UserRegistration_Screen.dart';
import 'CraftsmanRegistration_Screen.dart';
import 'Home_Screen.dart';
import 'Categories_Screen.dart';
import 'CraftsmanList_Screen.dart';
import 'CraftsmanDetails_Screen.dart';
import 'CraftsmanProfile_Screen.dart';
import 'EditCraftsmanProfile_Screen.dart';
import 'CraftsmanJobs_Screen.dart';
import 'Booking_Screen.dart';
import 'Profile_Screen.dart';
import 'Todo_Screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حِرَفي',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
      ),
      
      initialRoute: '/',
      
      routes: <String, WidgetBuilder>{
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthScreen(),
        '/login': (context) => const LoginScreen(),

        '/user_registration': (context) => const UserRegistrationScreen(),
        '/craftsman_registration': (context) => const CraftsmanRegistrationScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/todo': (context) => const TodoScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/craftsman_profile': (context) => const CraftsmanProfileScreen(),
        '/edit_craftsman_profile': (context) => const EditCraftsmanProfileScreen(),
        '/craftsman_jobs': (context) => const CraftsmanJobsScreen(),
        
        '/craftsman_home': (context) => const CraftsmanHomeScreen(),
        // ✅ الروابط الجديدة المضافة
        '/qr_scanner': (context) => const PlaceholderScreen(title: 'ماسح QR'),
        '/notifications': (context) => const PlaceholderScreen(title: 'الإشعارات'),
        '/voice_search': (context) => const PlaceholderScreen(title: 'البحث الصوتي'),
        '/discounts': (context) => const PlaceholderScreen(title: 'العروض والخصومات'),
        '/featured_craftsmen': (context) => const PlaceholderScreen(title: 'الحرفيون المميزون'),
        '/my_bookings': (context) => const PlaceholderScreen(title: 'حجوزاتي'),
        '/messages': (context) => const PlaceholderScreen(title: 'الرسائل'),
        '/order_history': (context) => const PlaceholderScreen(title: 'سجل الطلبات'),
        '/favorites': (context) => const PlaceholderScreen(title: 'المفضلة'),
        '/wallet': (context) => const PlaceholderScreen(title: 'المحفظة'),
        '/addresses': (context) => const PlaceholderScreen(title: 'عناويني'),
        '/settings': (context) => const PlaceholderScreen(title: 'الإعدادات'),
        '/help': (context) => const PlaceholderScreen(title: 'المساعدة'),
        '/advanced_search': (context) => const PlaceholderScreen(title: 'البحث المتقدم'),
        '/recent_craftsmen': (context) => const PlaceholderScreen(title: 'آخر الحرفيين'),
      },
      
      onGenerateRoute: (settings) {
        if (settings.name == '/craftsman_list') {
          final String categoryName = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => CraftsmanListScreen(categoryName: categoryName),
          );
        }
        
        if (settings.name == '/craftsman_details') {
          final String craftsmanId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => CraftsmanDetailsScreen(craftsmanId: craftsmanId),
          );
        }
        
        if (settings.name == '/booking') {
          if (settings.arguments is Map<String, dynamic>) {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => BookingScreen(
                craftsmanId: args['craftsmanId'] ?? '',
                craftsmanName: args['craftsmanName'] ?? '',
                craftsmanCategory: args['craftsmanCategory'] ?? '',
              ),
            );
          }
        }
        
        // ✅ Chat route
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PlaceholderScreen(
              title: 'محادثة مع ${args['name']}',
            ),
          );
        }
        
        return null;
      },
    );
  }
}

// ✅ شاشة بديلة للصفحات غير المكتملة
class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'صفحة $title',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'قيد التطوير حالياً',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('رجوع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}