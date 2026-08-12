import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../widgets/form_section.dart';
import '../widgets/image_preview.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? existing;
  const CategoryFormScreen({super.key, this.existing});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _imageUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _imageUrl = TextEditingController(text: widget.existing?.imageUrl ?? '');
    
    // Add listener to update image preview in real-time
    _imageUrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Category' : 'Add Category')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            ImagePreview(imageUrl: _imageUrl.text),
            24.verticalSpace,
            FormSection(
              title: 'Basic Details',
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    hintText: 'Category Name',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                16.verticalSpace,
                TextField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                    hintText: 'Image URL',
                    prefixIcon: Icon(Icons.image_search_outlined),
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
                          strokeWidth: 2,
                          color: AppColors.textDark,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Category'),
              ),
            ),
            if (isEditing) ...[
              12.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: _saving ? null : _delete,
                  child: const Text('Delete Category'),
                ),
              ),
            ],
            // Added some bottom padding for better scroll feel
            20.verticalSpace,
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final newName = _name.text.trim();
    if (newName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name must be at least 2 characters long')),
      );
      return;
    }
    
    setState(() => _saving = true);
    final Map<String, dynamic> data = {
      'name': newName,
      'image_url': _imageUrl.text.trim()
    };
    try {
      final firestore = FirebaseFirestore.instance;
      if (widget.existing != null) {
        final oldName = widget.existing!.name;
        final batch = firestore.batch();
        
        // Update category document
        batch.update(firestore.collection('categories').doc(widget.existing!.id), data);
        
        // If name changed, update all items linked to this category
        if (newName != oldName) {
          final items = await firestore.collection('menu_items')
              .where('category', isEqualTo: oldName)
              .get();
          for (var doc in items.docs) {
            batch.update(doc.reference, {'category': newName});
          }
        }
        await batch.commit();
      } else {
        // Get current count to set order
        final count = (await firestore.collection('categories').count().get()).count;
        data['order'] = count ?? 0;
        await firestore.collection('categories').add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text('This will not delete items in this category, but they might become unorganized.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('categories').doc(widget.existing!.id).delete();
      if (mounted) Navigator.pop(context);
    }
  }
}
