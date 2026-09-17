import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'category_form_screen.dart';
import 'category_items_screen.dart';
import 'reorder_categories_screen.dart';

class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Reorder Categories',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReorderCategoriesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryFormScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(message: 'Could not load menu categories');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }
          
          final categories = snapshot.data?.docs.map((d) => 
            Category.fromFirestore(d.id, d.data() as Map<String, dynamic>)
          ).toList() ?? [];

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64.sp, color: AppColors.gold),
                  16.verticalSpace,
                  Text('No categories yet', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  8.verticalSpace,
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoryFormScreen()),
                    ),
                    child: const Text('Add First Category'),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  (constraints.maxWidth / 190.w).floor().clamp(2, 5).toInt();
              return GridView.builder(
                padding: EdgeInsets.all(16.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.9,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CategoryItemsScreen(category: cat)),
                      ),
                      onLongPress: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CategoryFormScreen(existing: cat)),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: cat.imageUrl.isNotEmpty
                                    ? Image.network(
                                        cat.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.restaurant,
                                          size: 40.sp,
                                          color: AppColors.gold,
                                        ),
                                      )
                                    : ColoredBox(
                                        color: AppColors.cream,
                                        child: Icon(Icons.restaurant,
                                            size: 40.sp,
                                            color: AppColors.gold),
                                      ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 4.h,
                            right: 4.w,
                            child: CircleAvatar(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.8),
                              radius: 16.r,
                              child: IconButton(
                                icon: Icon(Icons.edit,
                                    size: 16.sp, color: AppColors.maroon),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          CategoryFormScreen(existing: cat)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  const _LoadError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48.sp, color: AppColors.error),
            12.verticalSpace,
            Text(message, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp)),
            6.verticalSpace,
            Text('Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }
}
