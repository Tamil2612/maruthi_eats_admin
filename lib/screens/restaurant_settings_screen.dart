import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/restaurant_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/form_section.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  RestaurantSettings? _settings;

  final TextEditingController _minOrderController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _maxDistController = TextEditingController();
  final TextEditingController _pauseReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _minOrderController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _maxDistController.dispose();
    _pauseReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('restaurant')
          .get();
      if (doc.exists && doc.data() != null) {
        _settings = RestaurantSettings.fromFirestore(doc.data()!);
      } else {
        _settings = RestaurantSettings.defaultSettings();
      }

      _minOrderController.text = _settings!.minimumOrderValue.toString();
      _latController.text = _settings!.delivery.restaurantLatitude.toString();
      _lngController.text = _settings!.delivery.restaurantLongitude.toString();
      _maxDistController.text =
          _settings!.delivery.maxDeliveryDistanceKm.toString();
      _pauseReasonController.text = _settings!.pause.reason;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading settings: $e'),
              backgroundColor: AppColors.error),
        );
      }
      _settings = RestaurantSettings.defaultSettings();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate slabs
    if (_settings != null) {
      final slabs = _settings!.delivery.slabs;
      for (int i = 0; i < slabs.length; i++) {
        if (slabs[i].upToKm <= 0 || slabs[i].fee < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Delivery slabs must have positive distances and non-negative fees'),
                backgroundColor: AppColors.error),
          );
          return;
        }
        if (i > 0 && slabs[i].upToKm <= slabs[i - 1].upToKm) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Delivery slabs must be sorted by distance and cannot overlap'),
                backgroundColor: AppColors.error),
          );
          return;
        }
      }
    }

    setState(() => _saving = true);
    try {
      _settings!.minimumOrderValue =
          double.tryParse(_minOrderController.text) ?? 150.0;
      _settings!.delivery.restaurantLatitude =
          double.tryParse(_latController.text) ?? 0.0;
      _settings!.delivery.restaurantLongitude =
          double.tryParse(_lngController.text) ?? 0.0;
      _settings!.delivery.maxDeliveryDistanceKm =
          double.tryParse(_maxDistController.text) ?? 8.0;
      _settings!.pause.reason = _pauseReasonController.text.trim();

      await FirebaseFirestore.instance
          .collection('settings')
          .doc('restaurant')
          .set(_settings!.toMap(), SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Restaurant settings saved successfully!'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving settings: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _applyPause(int? minutes) {
    setState(() {
      _settings!.pause.isPaused = true;
      if (minutes != null) {
        _settings!.pause.pausedUntil =
            DateTime.now().add(Duration(minutes: minutes));
      } else {
        _settings!.pause.pausedUntil = null; // until resumed
      }
    });
  }

  void _resumeOperations() {
    setState(() {
      _settings!.pause.isPaused = false;
      _settings!.pause.pausedUntil = null;
      _settings!.pause.reason = '';
      _pauseReasonController.clear();
    });
  }

  void _addSpecialClosure() {
    String date = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    String reason = 'Holiday';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Special Closure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(text: date),
                onChanged: (val) => date = val,
              ),
              16.verticalSpace,
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: Icon(Icons.event_busy),
                ),
                controller: TextEditingController(text: reason),
                onChanged: (val) => reason = val,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _settings!.specialClosures.add(
                      SpecialClosure(date: date, closed: true, reason: reason));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant Settings')),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.maroon)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Settings'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _saving ? null : _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            // A. Restaurant Status
            FormSection(
              title: 'Restaurant Status',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Accepting Orders',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_settings!.isOpen
                      ? 'Restaurant is OPEN'
                      : 'Restaurant is CLOSED manually'),
                  value: _settings!.isOpen,
                  activeColor: AppColors.success,
                  onChanged: (val) => setState(() => _settings!.isOpen = val),
                ),
              ],
            ),
            20.verticalSpace,

            // B. Temporary Pause
            FormSection(
              title: 'Temporary Pause',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Paused Status',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_settings!.pause.isActive
                      ? 'Paused until ${_settings!.pause.pausedUntil?.toLocal() ?? "Indefinitely"}'
                      : 'Not paused'),
                  value: _settings!.pause.isPaused,
                  activeColor: AppColors.error,
                  onChanged: (val) {
                    if (val) {
                      _applyPause(30);
                    } else {
                      _resumeOperations();
                    }
                  },
                ),
                if (_settings!.pause.isPaused) ...[
                  16.verticalSpace,
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      ActionChip(
                          label: const Text('15 mins'),
                          onPressed: () => _applyPause(15)),
                      ActionChip(
                          label: const Text('30 mins'),
                          onPressed: () => _applyPause(30)),
                      ActionChip(
                          label: const Text('60 mins'),
                          onPressed: () => _applyPause(60)),
                      ActionChip(
                          label: const Text('Until Resumed'),
                          onPressed: () => _applyPause(null)),
                      ActionChip(
                        label: const Text('Resume Now',
                            style: TextStyle(color: Colors.white)),
                        backgroundColor: AppColors.success,
                        onPressed: _resumeOperations,
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  TextFormField(
                    controller: _pauseReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Pause Reason',
                      hintText: 'e.g. Kitchen overloaded / Rush hour',
                      prefixIcon: Icon(Icons.comment_outlined),
                    ),
                  ),
                ],
              ],
            ),
            20.verticalSpace,

            // C. Minimum Order
            FormSection(
              title: 'Minimum Order Value',
              children: [
                TextFormField(
                  controller: _minOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Order Value',
                    hintText: '150',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (val) {
                    if (val == null ||
                        double.tryParse(val) == null ||
                        double.parse(val) < 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              ],
            ),
            20.verticalSpace,

            // D. Delivery Settings & Coordinates
            FormSection(
              title: 'Delivery & Coordinates',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Delivery Enabled',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _settings!.delivery.enabled,
                  activeColor: AppColors.success,
                  onChanged: (val) =>
                      setState(() => _settings!.delivery.enabled = val),
                ),
                16.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: '12.9716',
                          prefixIcon: Icon(Icons.explore_outlined),
                        ),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: '77.5946',
                          prefixIcon: Icon(Icons.explore),
                        ),
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,
                TextFormField(
                  controller: _maxDistController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Max Delivery Distance (km)',
                    hintText: '8.0',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                ),
              ],
            ),
            20.verticalSpace,

            // E. Delivery Fee Slabs
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
                      child: Text(
                        'DELIVERY FEE SLABS',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroon.withValues(alpha: 0.7),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.maroon),
                      onPressed: () => setState(() {
                        _settings!.delivery.slabs
                            .add(DeliverySlab(upToKm: 10.0, fee: 80.0));
                      }),
                    ),
                  ],
                ),
                ..._settings!.delivery.slabs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final slab = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: slab.upToKm.toString(),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Up to km',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              onChanged: (val) =>
                                  slab.upToKm = double.tryParse(val) ?? slab.upToKm,
                            ),
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: TextFormField(
                              initialValue: slab.fee.toString(),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Fee (₹)',
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              onChanged: (val) =>
                                  slab.fee = double.tryParse(val) ?? slab.fee,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () => setState(() =>
                                _settings!.delivery.slabs.removeAt(idx)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            20.verticalSpace,

            // F. Special Closures
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
                      child: Text(
                        'SPECIAL CLOSURES',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroon.withValues(alpha: 0.7),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.maroon),
                      onPressed: _addSpecialClosure,
                    ),
                  ],
                ),
                Container(
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
                  child: _settings!.specialClosures.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(16.r),
                          child: const Center(
                            child: Text('No special closures added yet.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _settings!.specialClosures.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final sc = _settings!.specialClosures[idx];
                            return ListTile(
                              leading: const Icon(Icons.event_busy,
                                  color: AppColors.maroon),
                              title: Text(sc.date,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(sc.reason),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error),
                                onPressed: () => setState(() =>
                                    _settings!.specialClosures.removeAt(idx)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            32.verticalSpace,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveSettings,
                child: _saving
                    ? SizedBox(
                        height: 20.sp,
                        width: 20.sp,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textDark))
                    : const Text('Save Settings'),
              ),
            ),
            24.verticalSpace,
          ],
        ),
      ),
    );
  }
}
