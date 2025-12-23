import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;

class CraftsmanRequestsScreen extends StatelessWidget {
  const CraftsmanRequestsScreen({Key? key}) : super(key: key);

  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color errorColor = const Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('الطلبات الجديدة'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: userId == null
          ? const Center(child: Text('يجب تسجيل الدخول'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('craftsmanId', isEqualTo: userId)
                  .where('status', isEqualTo: 'new') // يظهر فقط الطلبات الجديدة
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
                        Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات جديدة حالياً',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                // ✅ الفرز في التطبيق بدلاً من الفايربيس لتجنب مشكلة الـ Index
                final docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime); // تنازلي
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return _buildRequestCard(context, doc.id, data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final date = (data['appointmentDate'] as Timestamp?)?.toDate();
    final dateStr = date != null 
        ? intl.DateFormat('yyyy/MM/dd', 'ar').format(date) 
        : 'غير محدد';

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
                  data['customerName'] ?? 'عميل',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['serviceType'] ?? 'خدمة',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today, 'الموعد: $dateStr - ${data['appointmentTime']}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'الموقع: ${data['location'] ?? 'غير محدد'}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.description, 'التفاصيل: ${data['description'] ?? '-'}'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(context, docId, 'rejected'),
                    icon: Icon(Icons.close, color: errorColor),
                    label: Text('رفض', style: TextStyle(color: errorColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: errorColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(context, docId, 'confirmed'),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('قبول', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
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

  Future<void> _updateStatus(BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({'status': newStatus});
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'confirmed' ? 'تم قبول الطلب بنجاح' : 'تم رفض الطلب'),
          backgroundColor: newStatus == 'confirmed' ? secondaryColor : errorColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحديث الحالة')),
      );
    }
  }
}
