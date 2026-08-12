import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/form_section.dart';
import '../widgets/image_preview.dart';

class MenuItemFormScreen extends StatefulWidget {
  final MenuItem? existing;
  final String? initialCategory;

  const MenuItemFormScreen({super.key, this.existing, this.initialCategory});

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _discountPrice;
  String? _selectedCategory;
  late final TextEditingController _imageUrl;
  late bool _isVeg;
  late bool _hasDiscount;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(
        text: e != null ? e.price.toStringAsFixed(0) : '');
    _discountPrice = TextEditingController(
        text: e?.discountPrice != null
            ? e!.discountPrice!.toStringAsFixed(0)
            : '');
    _selectedCategory = e?.category ?? widget.initialCategory;
    _imageUrl = TextEditingController(text: e?.imageUrl ?? '');
    _isVeg = e?.isVeg ?? true;
    _hasDiscount = e?.hasDiscount ?? false;

    _imageUrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _discountPrice.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Item' : 'Add Item')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImagePreview(imageUrl: _imageUrl.text),
            24.verticalSpace,
            FormSection(
              title: 'Basic Info',
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    hintText: 'Item Name',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                ),
                16.verticalSpace,
                TextField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Short Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                16.verticalSpace,
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .orderBy('order')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data?.docs
                            .map((d) => d['name'] as String)
                            .toList() ??
                        [];
                    if (_selectedCategory != null &&
                        !categories.contains(_selectedCategory)) {
                      categories.add(_selectedCategory!);
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        hintText: 'Select Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    );
                  },
                ),
              ],
            ),
            20.verticalSpace,
            FormSection(
              title: 'Pricing & Availability',
              children: [
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Original Price (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                8.verticalSpace,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Enable Discount',
                      style: TextStyle(fontSize: 13.sp)),
                  value: _hasDiscount,
                  activeColor: AppColors.maroon,
                  onChanged: (v) => setState(() => _hasDiscount = v),
                ),
                if (_hasDiscount) ...[
                  8.verticalSpace,
                  TextField(
                    controller: _discountPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Discounted Price (₹)',
                      prefixIcon: Icon(Icons.discount_outlined),
                    ),
                  ),
                ],
                12.verticalSpace,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Vegetarian', style: TextStyle(fontSize: 13.sp)),
                  value: _isVeg,
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() => _isVeg = v),
                ),
              ],
            ),
            20.verticalSpace,
            FormSection(
              title: 'Media',
              children: [
                TextField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                    hintText: 'Image URL',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
              ],
            ),
            32.verticalSpace,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        height: 20.sp,
                        width: 20.sp,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textDark))
                    : Text(isEditing ? 'Save Changes' : 'Create Item'),
              ),
            ),
            if (isEditing) ...[
              12.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error),
                  onPressed: _saving ? null : _delete,
                  child: const Text('Delete Item'),
                ),
              ),
            ],
            40.verticalSpace,
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final priceStr = _price.text.trim();
    final price = double.tryParse(priceStr) ?? 0;

    if (name.isEmpty || priceStr.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Name, price, and category are required')));
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Original price must be greater than zero')));
      return;
    }

    double? discountPrice;
    if (_hasDiscount) {
      final discountPriceStr = _discountPrice.text.trim();
      discountPrice = double.tryParse(discountPriceStr);

      if (discountPrice == null || discountPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Discounted price must be greater than zero')));
        return;
      }

      if (discountPrice >= price) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Discounted price must be less than original price')));
        return;
      }
    }

    setState(() => _saving = true);

    final data = {
      'name': name,
      'description': _description.text.trim(),
      'price': price,
      'has_discount': _hasDiscount,
      'discount_price': _hasDiscount ? discountPrice : null,
      'category': _selectedCategory,
      'image_url': _imageUrl.text.trim(),
      'is_veg': _isVeg,
      'available': widget.existing?.available ?? true,
    };

    try {
      final collection = FirebaseFirestore.instance.collection('menu_items');
      if (widget.existing != null) {
        await collection.doc(widget.existing!.id).update(data);
      } else {
        await collection.add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this item?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('menu_items')
          .doc(widget.existing!.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }
}
