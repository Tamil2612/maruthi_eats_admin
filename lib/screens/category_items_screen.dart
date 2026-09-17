import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import 'menu_item_form_screen.dart';
import 'category_form_screen.dart';

class CategoryItemsScreen extends StatefulWidget {
  final Category category;

  const CategoryItemsScreen({super.key, required this.category});

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Edit Category',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      CategoryFormScreen(existing: widget.category)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menu_items')
                  .where('category', isEqualTo: widget.category.name)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child:
                          Text('Could not load menu items. Please try again.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.maroon));
                }

                final allItems = snapshot.data?.docs
                        .map((d) => MenuItem.fromFirestore(
                            d.id, d.data() as Map<String, dynamic>))
                        .toList() ??
                    [];

                final items = allItems
                    .where((item) => item.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (allItems.isEmpty) {
                  return _buildEmptyState();
                }

                if (items.isEmpty && _searchQuery.isNotEmpty) {
                  return _buildNoResultsState();
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => 12.verticalSpace,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return _MenuItemCard(item: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  MenuItemFormScreen(initialCategory: widget.category.name)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Dish'),
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
            bottom:
                BorderSide(color: AppColors.maroon.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: AppColors.cream,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: widget.category.imageUrl.isNotEmpty
                  ? Image.network(widget.category.imageUrl, fit: BoxFit.cover)
                  : Icon(Icons.category_outlined,
                      size: 30.sp, color: AppColors.gold),
            ),
          ),
          20.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.name,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.maroon,
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('menu_items')
                      .where('category', isEqualTo: widget.category.name)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Text(
                      '$count ${count == 1 ? 'Item' : 'Items'} available',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search dishes in this category...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu,
              size: 64.sp, color: AppColors.gold.withValues(alpha: 0.3)),
          16.verticalSpace,
          Text('No dishes added yet',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          8.verticalSpace,
          Text('Tap the button below to add your first dish',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          24.verticalSpace,
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MenuItemFormScreen(
                      initialCategory: widget.category.name)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add First Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64.sp, color: Colors.grey.shade300),
          16.verticalSpace,
          Text('No matching dishes found',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          4.verticalSpace,
          Text('Try a different search term',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = item.available;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MenuItemFormScreen(existing: item)),
          ),
          child: SizedBox(
            height: 110.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Section
                Stack(
                  children: [
                    Container(
                      width: 110.w,
                      decoration: const BoxDecoration(color: AppColors.cream),
                      child: ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(16.r)),
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                item.imageUrl,
                                width: 110.w,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.restaurant,
                                    size: 24.sp,
                                    color: AppColors.gold),
                              )
                            : Icon(Icons.restaurant,
                                size: 24.sp, color: AppColors.gold),
                      ),
                    ),
                    // Availability Dimming
                    if (!isAvailable)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(16.r)),
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.white, width: 1),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'SOLD OUT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 8.sp,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Veg/Non-Veg Badge
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(
                          Icons.circle,
                          size: 8.sp,
                          color: item.isVeg ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),

                // Info Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isAvailable
                                      ? AppColors.textDark
                                      : AppColors.textDark
                                          .withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined,
                                  size: 16.sp, color: AppColors.maroon),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        MenuItemFormScreen(existing: item)),
                              ),
                            ),
                          ],
                        ),
                        2.verticalSpace,
                        Text(
                          item.description.isNotEmpty
                              ? item.description
                              : 'No description provided',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        8.verticalSpace,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.hasDiscount &&
                                    item.discountPrice != null) ...[
                                  Text(
                                    '₹${item.discountPrice!.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isAvailable
                                          ? AppColors.maroon
                                          : AppColors.maroon
                                              .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey.shade400,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isAvailable
                                          ? AppColors.maroon
                                          : AppColors.maroon
                                              .withValues(alpha: 0.5),
                                    ),
                                  ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  isAvailable ? 'IN STOCK' : 'HIDDEN',
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isAvailable
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                20.horizontalSpace,
                                SizedBox(
                                  height: 20.h,
                                  width: 36.w,
                                  child: Switch.adaptive(
                                    value: isAvailable,
                                    activeTrackColor:
                                        AppColors.maroon.withValues(alpha: 0.5),
                                    activeThumbColor: AppColors.maroon,
                                    onChanged: (val) {
                                      FirebaseFirestore.instance
                                          .collection('menu_items')
                                          .doc(item.id)
                                          .update({'available': val});
                                    },
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
        ),
      ),
    );
  }
}
