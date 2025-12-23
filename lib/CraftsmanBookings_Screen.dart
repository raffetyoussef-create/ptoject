import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;

class CraftsmanBookingsScreen extends StatelessWidget {
  const CraftsmanBookingsScreen({Key? key}) : super(key: key);

  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color completeColor = const Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('جدول الحجوزات'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: userId == null
          ? const Center(child: Text('يجب تسجيل الدخول'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('craftsmanId', isEqualTo: userId)
                  .where('status', isEqualTo: 'confirmed') // يظهر فقط الحجوزات المؤكدة
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
                        Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد حجوزات مؤكدة حالياً',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                // ✅ الفرز في التطبيق بدلاً من الفايربيس لتجنب مشكلة الـ Index
                final docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aDate = (a.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp?;
                  final bDate = (b.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp?;
                  if (aDate == null || bDate == null) return 0;
                  return aDate.compareTo(bDate); // تصاعدي (الأقرب فالأبعد)
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return _buildBookingCard(context, doc.id, data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildBookingCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final dateToken = data['appointmentDate'] as Timestamp?;
    final date = dateToken?.toDate();
    final dateStr = date != null 
        ? intl.DateFormat('yyyy/MM/dd', 'ar').format(date) 
        : 'غير محدد';
    final timeStr = data['appointmentTime'] ?? 'غير محدد';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['serviceType'] ?? 'خدمة',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data['expectedPrice'] ?? 0} ج.م',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, 'العميل: ${data['customerName'] ?? 'غير معروف'}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'الموعد: $dateStr - $timeStr'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'الموقع: ${data['location'] ?? 'غير محدد'}'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _completeJob(context, docId),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('إتمام المهمة', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: completeColor,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  Future<void> _completeJob(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({'status': 'completed'}); // تغيير الحالة إلى مكتمل لجني الأرباح
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إتمام المهمة بنجاح، وإضافة المبلغ للأرباح!'),
          backgroundColor: completeColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحديث الحالة')),
      );
    }
  }
}
