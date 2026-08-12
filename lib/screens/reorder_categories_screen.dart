import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class ReorderCategoriesScreen extends StatefulWidget {
  const ReorderCategoriesScreen({super.key});

  @override
  State<ReorderCategoriesScreen> createState() =>
      _ReorderCategoriesScreenState();
}

class _ReorderCategoriesScreenState extends State<ReorderCategoriesScreen> {
  List<Category>? _categories;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Arrange Menu'),
        actions: [
          if (_categories != null)
            TextButton.icon(
              onPressed: _saving ? null : _saveOrder,
              icon: _saving
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.w, color: Colors.white))
                  : Icon(Icons.check_circle_outline,
                      size: 18.sp, color: AppColors.gold),
              label: Text(
                'Save',
                style: TextStyle(
                    color: _saving ? Colors.white54 : AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp),
              ),
            ),
          12.horizontalSpace,
        ],
      ),
      body: Column(
        children: [
          _buildInstructionHeader(),
          Expanded(
            child: _categories == null
                ? StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .orderBy('order')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.maroon));
                      }

                      final docs = snapshot.data!.docs;
                      _categories = docs
                          .map((d) => Category.fromFirestore(
                              d.id, d.data() as Map<String, dynamic>))
                          .toList();

                      return _buildReorderList();
                    },
                  )
                : _buildReorderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
            bottom:
                BorderSide(color: AppColors.maroon.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 14.sp, color: Colors.grey),
          8.horizontalSpace,
          Text(
            'Long press and drag items to rearrange',
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderList() {
    if (_categories!.isEmpty) {
      return const Center(child: Text('No categories to reorder'));
    }

    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
      itemCount: _categories!.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _categories!.removeAt(oldIndex);
          _categories!.insert(newIndex, item);
        });
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.transparent,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final cat = _categories![index];
        return Container(
          key: ValueKey(cat.id),
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            leading: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: cat.imageUrl.isNotEmpty
                    ? Image.network(
                        cat.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.category,
                            size: 20.sp, color: AppColors.gold),
                      )
                    : Icon(Icons.category, size: 20.sp, color: AppColors.gold),
              ),
            ),
            title: Text(
              cat.name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: AppColors.textDark),
            ),
            trailing: Icon(Icons.drag_indicator,
                color: Colors.grey.shade400, size: 20.sp),
          ),
        );
      },
    );
  }

  Future<void> _saveOrder() async {
    setState(() => _saving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < _categories!.length; i++) {
        batch.update(
          FirebaseFirestore.instance
              .collection('categories')
              .doc(_categories![i].id),
          {'order': i},
        );
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu order updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving order: $e')));
      }
    }
  }
}
