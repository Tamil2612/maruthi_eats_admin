import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/coupon.dart';
import '../theme/app_theme.dart';
import '../widgets/form_section.dart';

class CouponFormScreen extends StatefulWidget {
  final CouponModel? existing;
  const CouponFormScreen({super.key, this.existing});

  @override
  State<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends State<CouponFormScreen> {
  late final TextEditingController _code;
  late final TextEditingController _amount;
  late final TextEditingController _minOrder;
  late final TextEditingController _rules;
  DateTime? _expiryDate;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _code = TextEditingController(text: e?.code ?? '');
    _amount = TextEditingController(text: e != null ? e.amount.toStringAsFixed(0) : '');
    _minOrder = TextEditingController(text: e != null ? e.minOrderValue.toStringAsFixed(0) : '');
    _rules = TextEditingController(text: e?.rules ?? '');
    _expiryDate = e?.expiryDate;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _amount.dispose();
    _minOrder.dispose();
    _rules.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Coupon' : 'Create Coupon')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            FormSection(
              title: 'Coupon Identity',
              children: [
                TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                    hintText: 'Coupon Code (e.g. SAVE50)',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                16.verticalSpace,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Coupon Active', style: TextStyle(fontSize: 13.sp)),
                  value: _isActive,
                  activeColor: AppColors.maroon,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
            20.verticalSpace,
            FormSection(
              title: 'Discount & Limits',
              children: [
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Discount Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                16.verticalSpace,
                TextField(
                  controller: _minOrder,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Min Order Value (₹)',
                    prefixIcon: Icon(Icons.shopping_cart_outlined),
                  ),
                ),
                16.verticalSpace,
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _expiryDate == null
                        ? 'Set Expiry Date'
                        : 'Expires: ${DateFormat('dd MMM yyyy').format(_expiryDate!)}',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                  trailing: Icon(Icons.calendar_today, size: 18.sp, color: AppColors.maroon),
                  onTap: _pickExpiryDate,
                ),
              ],
            ),
            20.verticalSpace,
            FormSection(
              title: 'Rules & Regulations',
              children: [
                TextField(
                  controller: _rules,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Describe terms and conditions...',
                    prefixIcon: Icon(Icons.rule),
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
                    height: 20.sp, width: 20.sp,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                    : Text(isEditing ? 'Save Changes' : 'Create Coupon'),
              ),
            ),
            if (isEditing) ...[
              12.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: _saving ? null : _delete,
                  child: const Text('Delete Coupon'),
                ),
              ),
            ],
            40.verticalSpace,
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.maroon, onPrimary: Colors.white, surface: AppColors.cream),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    final code = _code.text.trim();
    final amount = double.tryParse(_amount.text.trim()) ?? 0;

    if (code.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid code and amount are required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final collection = FirebaseFirestore.instance.collection('coupons');
      final normalizedCode = code.toUpperCase();

      final existing = await collection.where('code', isEqualTo: normalizedCode).get();
      final duplicateExists = existing.docs.any((doc) => doc.id != widget.existing?.id);
      if (duplicateExists) {
        setState(() => _saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('A coupon with code "$normalizedCode" already exists')),
          );
        }
        return;
      }

      final data = {
        'code': normalizedCode,
        'amount': amount,
        'min_order_value': double.tryParse(_minOrder.text.trim()) ?? 0,
        'expiry_date': _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        'rules': _rules.text.trim(),
        'is_active': _isActive,
      };

      if (widget.existing != null) {
        await collection.doc(widget.existing!.id).update(data);
      } else {
        await collection.add(data);
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
        title: const Text('Delete Coupon?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('coupons').doc(widget.existing!.id).delete();
      if (mounted) Navigator.pop(context);
    }
  }
}