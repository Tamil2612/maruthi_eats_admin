import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';

/// Result of a multi-select [MenuItemPicker] session: newly checked items
/// plus the ids of any previously-selected items the user unchecked, so
/// callers can both add and remove from their existing selection.
class MenuItemPickerResult {
  final List<MenuItem> added;
  final Set<String> removedIds;
  const MenuItemPickerResult({required this.added, required this.removedIds});
}

class MenuItemPicker extends StatefulWidget {
  final bool multiSelect;
  final List<String> initialSelectedIds;

  const MenuItemPicker({
    super.key,
    this.multiSelect = false,
    this.initialSelectedIds = const [],
  });

  @override
  State<MenuItemPicker> createState() => _MenuItemPickerState();
}

class _MenuItemPickerState extends State<MenuItemPicker> {
  final List<MenuItem> _selectedItems = [];
  final Set<String> _deselectedInitialIds = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 0.85.sh,
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.multiSelect ? 'Select Items' : 'Select an Item',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
                ),
                if (widget.multiSelect)
                  TextButton(
                    onPressed: () => Navigator.pop(context, MenuItemPickerResult(
                      added: _selectedItems,
                      removedIds: _deselectedInitialIds,
                    )),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.maroon,
                      textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                    child: const Text('Done'),
                  )
                else
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            16.verticalSpace,
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search dishes...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                filled: true,
                fillColor: AppColors.cream.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('menu_items')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 40.sp, color: AppColors.error),
                          8.verticalSpace,
                          Text('Error loading items',
                              style: TextStyle(
                                  color: AppColors.error, fontSize: 13.sp)),
                          Text(snapshot.error.toString(),
                              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.maroon));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48.sp, color: Colors.grey.shade300),
                          12.verticalSpace,
                          const Text('No products found in menu'),
                        ],
                      ),
                    );
                  }

                  final items = docs
                      .map((d) => MenuItem.fromFirestore(
                          d.id, d.data() as Map<String, dynamic>))
                      .where((i) => i.name.toLowerCase().contains(_searchQuery))
                      .toList();

                  if (items.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_outlined,
                              size: 48.sp, color: Colors.grey.shade300),
                          12.verticalSpace,
                          Text('No results for "$_searchQuery"'),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isPreSelected = widget.initialSelectedIds.contains(item.id) &&
                          !_deselectedInitialIds.contains(item.id);
                      final isSelected = _selectedItems.any((i) => i.id == item.id) || isPreSelected;

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                        leading: Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            color: AppColors.cream,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.restaurant))
                                : const Icon(Icons.restaurant),
                          ),
                        ),
                        title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                        subtitle: Text('₹${item.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp, color: AppColors.maroon, fontWeight: FontWeight.bold)),
                        trailing: widget.multiSelect
                            ? Checkbox(
                          value: isSelected,
                          activeColor: AppColors.maroon,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _deselectedInitialIds.remove(item.id);
                                if (!_selectedItems.any((i) => i.id == item.id)) {
                                  _selectedItems.add(item);
                                }
                              } else {
                                _selectedItems.removeWhere((i) => i.id == item.id);
                                if (widget.initialSelectedIds.contains(item.id)) {
                                  _deselectedInitialIds.add(item.id);
                                }
                              }
                            });
                          },
                        )
                            : Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline,
                            color: isSelected ? AppColors.maroon : Colors.grey.shade300,
                            size: 24.sp),
                        onTap: () {
                          if (widget.multiSelect) {
                            final currentVal = isSelected;
                            setState(() {
                              if (!currentVal) {
                                _deselectedInitialIds.remove(item.id);
                                if (!_selectedItems.any((i) => i.id == item.id)) {
                                  _selectedItems.add(item);
                                }
                              } else {
                                _selectedItems.removeWhere((i) => i.id == item.id);
                                if (widget.initialSelectedIds.contains(item.id)) {
                                  _deselectedInitialIds.add(item.id);
                                }
                              }
                            });
                          } else {
                            Navigator.pop(context, item);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
