import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late AnimationController _fadeController;
  
  final _todoController = TextEditingController();
  String _filterStatus = 'all'; // all, pending, completed

  // لوحة ألوان فخمة (بنفسجي نيون)
  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color accentColor = const Color(0xFFAB47BC);
  final Color successColor = const Color(0xFF00C853);
  final Color bgColor = const Color(0xFFF3E5F5);
  
  Color? get backgroundColor => null;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _todoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // --- منطق البيانات (Logic) ---

  Stream<QuerySnapshot> _getTodosStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    Query query = _firestore.collection('todos')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);
    
    if (_filterStatus == 'pending') {
      query = query.where('completed', isEqualTo: false);
    } else if (_filterStatus == 'completed') {
      query = query.where('completed', isEqualTo: true);
    }
    return query.snapshots();
  }

  // --- بناء الواجهة (UI Construction) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, accentColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsSummary(),
              _buildFilterTabs(),
              Expanded(child: _buildTodoListContainer()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCustomFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBlurButton(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
          const Column(
            children: [
              Text('مدير المهام', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('نظم أعمالك الحرفية بذكاء', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          _buildBlurButton(Icons.more_vert, () {}),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('todos').where('userId', isEqualTo: _auth.currentUser?.uid).snapshots(),
      builder: (context, snapshot) {
        int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
        int completed = snapshot.hasData ? snapshot.data!.docs.where((d) => d['completed'] == true).length : 0;
        int pending = total - completed;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              _buildStatChip('الكل', total.toString(), Colors.white24),
              const SizedBox(width: 10),
              _buildStatChip('قيد التنفيذ', pending.toString(), Colors.orangeAccent.withOpacity(0.3)),
              const SizedBox(width: 10),
              _buildStatChip('مكتملة', completed.toString(), successColor.withOpacity(0.3)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodoListContainer() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
        child: StreamBuilder<QuerySnapshot>(
          stream: _getTodosStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) return _buildEmptyState();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var todo = snapshot.data!.docs[index];
                var data = todo.data() as Map<String, dynamic>;
                return _buildTaskCard(todo.id, data, index);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(String id, Map<String, dynamic> data, int index) {
    bool isDone = data['completed'] ?? false;
    
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 30 * (1 - value)), child: child),
      ),
      child: Dismissible(
        key: Key(id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteTodo(id),
        background: _buildDeleteBackground(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: isDone ? Colors.grey[50] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: isDone ? Colors.transparent : primaryColor.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: _buildCheckbox(id, isDone),
            title: Text(
              data['title'] ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isDone ? FontWeight.normal : FontWeight.bold,
                color: isDone ? Colors.grey : Colors.black87,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit_note_rounded, color: primaryColor.withOpacity(0.5)),
              onPressed: () => _editTodo(id, data['title']),
            ),
          ),
        ),
      ),
    );
  }

  // --- الأدوات المساعدة للتصميم (Helper Widgets) ---

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(String id, bool isDone) {
    return InkWell(
      onTap: () => _toggleTodo(id, isDone),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: isDone ? successColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isDone ? successColor : Colors.grey.shade400, width: 2),
        ),
        child: isDone ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }

  Widget _buildCustomFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddTodoDialog,
      backgroundColor: primaryColor,
      elevation: 8,
      icon: const Icon(Icons.add_task_rounded, color: Colors.white),
      label: const Text('إضافة مهمة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 30),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 35),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 100, color: primaryColor.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text('لا يوجد مهام حالياً', style: TextStyle(color: primaryColor.withOpacity(0.4), fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
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

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          _buildTab('الكل', 'all'),
          _buildTab('بانتظارك', 'pending'),
          _buildTab('انتهيت', 'completed'),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String value) {
    bool isSelected = _filterStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? primaryColor : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

  // --- دوال العمليات (Methods) ---

  Future<void> _addTodo() async {
    if (_todoController.text.trim().isEmpty) return;
    try {
      await _firestore.collection('todos').add({
        'userId': _auth.currentUser!.uid,
        'title': _todoController.text.trim(),
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _todoController.clear();
      if (mounted) Navigator.pop(context);
      _showSnackBar('تم إضافة المهمة بنجاح ✅', Colors.green);
    } catch (e) {
      _showSnackBar('فشل الإضافة ❌', Colors.red);
    }
  }

  Future<void> _toggleTodo(String id, bool current) async {
    await _firestore.collection('todos').doc(id).update({'completed': !current});
  }

  Future<void> _deleteTodo(String id) async {
    await _firestore.collection('todos').doc(id).delete();
  }

  Future<void> _editTodo(String id, String oldTitle) async {
    final controller = TextEditingController(text: oldTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('تعديل المهمة', textAlign: TextAlign.right),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              _firestore.collection('todos').doc(id).update({'title': controller.text.trim()});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddTodoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text('ماذا تنوي فعله اليوم؟ 🛠️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _todoController,
                textAlign: TextAlign.right,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'مثلاً: شراء قطع غيار للسباكة...',
                  filled: true, fillColor: bgColor.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _addTodo,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text('حفظ المهمة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.right), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }
}