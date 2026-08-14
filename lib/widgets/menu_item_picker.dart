import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';

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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.8.sh,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.multiSelect ? 'Select Items' : 'Select an Item',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
              ),
              if (widget.multiSelect)
                TextButton(
                  onPressed: () => Navigator.pop(context, _selectedItems),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
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
            ),
          ),
          16.verticalSpace,
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu_items').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final items = snapshot.data!.docs
                    .map((d) => MenuItem.fromFirestore(d.id, d.data() as Map<String, dynamic>))
                    .where((i) => i.name.toLowerCase().contains(_searchQuery))
                    .toList();

                if (items.isEmpty) return const Center(child: Text('No matching items found'));

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedItems.any((i) => i.id == item.id) || 
                                     widget.initialSelectedIds.contains(item.id);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(item.imageUrl, width: 40.w, height: 40.w, fit: BoxFit.cover)
                            : Container(width: 40.w, height: 40.w, color: AppColors.cream, child: const Icon(Icons.restaurant)),
                      ),
                      title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                      subtitle: Text('₹${item.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp)),
                      trailing: widget.multiSelect
                          ? Checkbox(
                              value: isSelected,
                              activeColor: AppColors.maroon,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedItems.add(item);
                                  } else {
                                    _selectedItems.removeWhere((i) => i.id == item.id);
                                  }
                                });
                              },
                            )
                          : Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, 
                                 color: isSelected ? AppColors.maroon : Colors.grey),
                      onTap: widget.multiSelect 
                        ? null 
                        : () => Navigator.pop(context, item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
