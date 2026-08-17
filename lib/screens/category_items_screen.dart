import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import 'menu_item_form_screen.dart';
import 'category_form_screen.dart';

class CategoryItemsScreen extends StatelessWidget {
  final Category category;
  const CategoryItemsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Edit Category',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CategoryFormScreen(existing: category)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('menu_items')
            .where('category', isEqualTo: category.name)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }
          
          final items = snapshot.data?.docs.map((d) => 
            MenuItem.fromFirestore(d.id, d.data() as Map<String, dynamic>)
          ).toList() ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64.sp, color: AppColors.gold.withValues(alpha: 0.5)),
                  16.verticalSpace,
                  Text('No items in this category', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
                  24.verticalSpace,
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MenuItemFormScreen(initialCategory: category.name)),
                    ),
                    child: const Text('Add First Item'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: items.length,
            separatorBuilder: (context, index) => 12.verticalSpace,
            itemBuilder: (context, i) {
              final item = items[i];
              return _MenuItemCard(item: item);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuItemFormScreen(initialCategory: category.name)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
                color: AppColors.cream,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.restaurant, size: 30.sp, color: AppColors.gold),
                      )
                    : Icon(Icons.restaurant, size: 30.sp, color: AppColors.gold),
              ),
            ),
            
            // Info Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12.sp,
                          color: item.isVeg ? Colors.green : Colors.red,
                        ),
                        8.horizontalSpace,
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    4.verticalSpace,
                    if (item.description.isNotEmpty)
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textDark.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.hasDiscount && item.discountPrice != null) ...[
                              Text(
                                '₹${item.discountPrice!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.maroon,
                                ),
                              ),
                              Text(
                                '₹${item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ] else
                              Text(
                                '₹${item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.maroon,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            Switch.adaptive(
                              value: item.available,
                              activeColor: AppColors.maroon,
                              onChanged: (val) {
                                FirebaseFirestore.instance
                                    .collection('menu_items')
                                    .doc(item.id)
                                    .update({'available': val});
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 18.sp, color: AppColors.maroon),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MenuItemFormScreen(existing: item)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
