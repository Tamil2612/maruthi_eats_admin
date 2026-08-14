import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/offer.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/form_section.dart';
import '../widgets/menu_item_picker.dart';

class OfferFormScreen extends StatefulWidget {
  final OfferModel? existing;
  const OfferFormScreen({super.key, this.existing});

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _comboPrice;
  OfferType _type = OfferType.combo;
  bool _isActive = true;
  DateTime? _expiryDate;
  
  // Combo fields
  List<OfferItem> _bundleItems = [];

  // BOGO fields
  MenuItem? _buyItem;
  int _buyQty = 2;
  MenuItem? _getItem;
  int _getQty = 1;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _comboPrice = TextEditingController(text: e != null ? e.comboPrice.toStringAsFixed(0) : '');
    _type = e?.type ?? OfferType.combo;
    _isActive = e?.isActive ?? true;
    _expiryDate = e?.expiryDate;
    _bundleItems = List.from(e?.bundleItems ?? []);
    
    // In a real app, you'd fetch the MenuItem objects if buyItemId exists. 
    // For now, if editing BOGO, we might just show names or require re-selection.
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Offer' : 'New Special Offer')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _buildTypeSelector(),
            20.verticalSpace,
            FormSection(
              title: 'General Info',
              children: [
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(hintText: 'Offer Title', prefixIcon: Icon(Icons.star_outline)),
                ),
                16.verticalSpace,
                TextField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Public Description', prefixIcon: Icon(Icons.description_outlined)),
                ),
                16.verticalSpace,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Active Offer', style: TextStyle(fontSize: 14.sp)),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
            20.verticalSpace,
            if (_type == OfferType.combo) _buildComboSection() else _buildBogoSection(),
            20.verticalSpace,
            FormSection(
              title: 'Schedule',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_expiryDate == null ? 'No Expiry Date' : 'Expires: ${DateFormat('dd MMM yyyy').format(_expiryDate!)}'),
                  trailing: Icon(Icons.calendar_month, color: AppColors.maroon, size: 20.sp),
                  onTap: _pickDate,
                ),
              ],
            ),
            32.verticalSpace,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving 
                    ? const CircularProgressIndicator(color: AppColors.textDark) 
                    : Text(isEditing ? 'Save Changes' : 'Create Offer'),
              ),
            ),
            if (isEditing) ...[
              12.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: _delete,
                  child: const Text('Remove Offer'),
                ),
              ),
            ],
            40.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Expanded(child: _typeTab('Combo / Bundle', OfferType.combo)),
          Expanded(child: _typeTab('Buy X Get Y', OfferType.bogo)),
        ],
      ),
    );
  }

  Widget _typeTab(String label, OfferType type) {
    final active = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.maroon : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildComboSection() {
    return FormSection(
      title: 'Bundle Items & Price',
      children: [
        ..._bundleItems.map((item) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.itemName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQty(item, -1)),
              Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateQty(item, 1)),
            ],
          ),
        )),
        TextButton.icon(
          onPressed: _pickBundleItems,
          icon: const Icon(Icons.add),
          label: const Text('Add Items to Bundle'),
        ),
        16.verticalSpace,
        TextField(
          controller: _comboPrice,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Bundle Price (₹)', prefixIcon: Icon(Icons.currency_rupee)),
        ),
      ],
    );
  }

  Widget _buildBogoSection() {
    return FormSection(
      title: 'Condition & Reward',
      children: [
        _selectionTile(
          label: 'Buy Item',
          selected: _buyItem?.name ?? widget.existing?.buyItemName ?? 'Select dish...',
          onTap: () async {
            final res = await _showPicker();
            if (res != null) setState(() => _buyItem = res);
          },
        ),
        Row(
          children: [
            const Text('Buy Quantity:'),
            const Spacer(),
            IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _buyQty = (_buyQty > 1 ? _buyQty - 1 : 1))),
            Text('$_buyQty', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _buyQty++)),
          ],
        ),
        const Divider(),
        _selectionTile(
          label: 'Get FREE Item',
          selected: _getItem?.name ?? widget.existing?.getItemName ?? 'Select dish...',
          onTap: () async {
            final res = await _showPicker();
            if (res != null) setState(() => _getItem = res);
          },
        ),
        Row(
          children: [
            const Text('Free Quantity:'),
            const Spacer(),
            IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _getQty = (_getQty > 1 ? _getQty - 1 : 1))),
            Text('$_getQty', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _getQty++)),
          ],
        ),
      ],
    );
  }

  Widget _selectionTile({required String label, required String selected, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
      subtitle: Text(selected, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<MenuItem?> _showPicker() => showModalBottomSheet<MenuItem>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const MenuItemPicker(),
  );

  void _pickBundleItems() async {
    final List<MenuItem>? results = await showModalBottomSheet<List<MenuItem>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MenuItemPicker(multiSelect: true, initialSelectedIds: _bundleItems.map((e) => e.itemId).toList()),
    );
    if (results != null) {
      setState(() {
        for (var res in results) {
          if (!_bundleItems.any((e) => e.itemId == res.id)) {
            _bundleItems.add(OfferItem(itemId: res.id, itemName: res.name, qty: 1));
          }
        }
      });
    }
  }

  void _updateQty(OfferItem item, int delta) {
    setState(() {
      final idx = _bundleItems.indexOf(item);
      final newQty = item.qty + delta;
      if (newQty <= 0) {
        _bundleItems.removeAt(idx);
      } else {
        _bundleItems[idx] = OfferItem(itemId: item.itemId, itemName: item.itemName, qty: newQty);
      }
    });
  }

  Future<void> _pickDate() async {
    final res = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (res != null) setState(() => _expiryDate = res);
  }

  Future<void> _save() async {
    if (_title.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    setState(() => _saving = true);
    final data = {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'type': _type == OfferType.bogo ? 'bogo' : 'combo',
      'is_active': _isActive,
      'expiry_date': _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
      'bundle_items': _bundleItems.map((e) => e.toMap()).toList(),
      'combo_price': double.tryParse(_comboPrice.text) ?? 0,
      'buy_item_id': _buyItem?.id ?? widget.existing?.buyItemId,
      'buy_item_name': _buyItem?.name ?? widget.existing?.buyItemName,
      'buy_qty': _buyQty,
      'get_item_id': _getItem?.id ?? widget.existing?.getItemId,
      'get_item_name': _getItem?.name ?? widget.existing?.getItemName,
      'get_qty': _getQty,
    };
    try {
      if (widget.existing != null) {
        await FirebaseFirestore.instance.collection('offers').doc(widget.existing!.id).update(data);
      } else {
        await FirebaseFirestore.instance.collection('offers').add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance.collection('offers').doc(widget.existing!.id).delete();
    if (mounted) Navigator.pop(context);
  }
}
