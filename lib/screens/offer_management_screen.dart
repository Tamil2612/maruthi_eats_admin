import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/offer.dart';
import '../theme/app_theme.dart';
import 'offer_form_screen.dart';

class OfferManagementScreen extends StatelessWidget {
  const OfferManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('offers').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final offers = snapshot.data!.docs.map((d) => 
            OfferModel.fromFirestore(d.id, d.data() as Map<String, dynamic>)
          ).toList();

          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars_outlined, size: 64.sp, color: AppColors.gold.withValues(alpha: 0.3)),
                  16.verticalSpace,
                  const Text('No special offers created yet', style: TextStyle(fontWeight: FontWeight.bold)),
                  24.verticalSpace,
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfferFormScreen())),
                    child: const Text('Create First Offer'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: offers.length,
            separatorBuilder: (_, __) => 12.verticalSpace,
            itemBuilder: (context, i) => _OfferCard(offer: offers[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfferFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OfferFormScreen(existing: offer))),
        title: Row(
          children: [
            Expanded(child: Text(offer.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp))),
            _TypeBadge(type: offer.type),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            8.verticalSpace,
            Text(offer.description, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600), maxLines: 2),
            12.verticalSpace,
            Row(
              children: [
                if (offer.type == OfferType.combo)
                  Text('Price: ₹${offer.comboPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.maroon, fontSize: 16.sp))
                else
                  Text('Buy ${offer.buyQty} Get ${offer.getQty} Free', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.maroon, fontSize: 14.sp)),
                const Spacer(),
                Switch.adaptive(
                  value: offer.isActive,
                  activeColor: AppColors.maroon,
                  onChanged: (v) {
                    FirebaseFirestore.instance.collection('offers').doc(offer.id).update({'is_active': v});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final OfferType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isCombo = type == OfferType.combo;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: (isCombo ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        isCombo ? 'COMBO' : 'REWARD',
        style: TextStyle(
          fontSize: 9.sp, 
          fontWeight: FontWeight.w900, 
          color: isCombo ? Colors.blue.shade800 : Colors.orange.shade800
        ),
      ),
    );
  }
}
