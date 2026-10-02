import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

class NewOrderOverlay extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  /// How many orders are waiting for a decision (including this one).
  final int pendingCount;

  const NewOrderOverlay({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDismiss,
    this.pendingCount = 1,
  });

  @override
  State<NewOrderOverlay> createState() => _NewOrderOverlayState();
}

class _NewOrderOverlayState extends State<NewOrderOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  OrderModel get order => widget.order;

  bool get _flagged =>
      order.validationStatus != null && order.validationStatus != 'ok';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.maroon,
              AppColors.maroonDark,
              Color(0xFF12020A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            child: Column(
              children: [
                _buildHeader(),
                8.verticalSpace,
                _buildPulsingIcon(),
                Text(
                  'New Order Received!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.gold,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                16.verticalSpace,
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: SingleChildScrollView(child: _buildCard()),
                  ),
                ),
                16.verticalSpace,
                _buildAcceptButton(),
                4.verticalSpace,
                TextButton(
                  onPressed: widget.onDismiss,
                  child: Text(
                    'Dismiss for now',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14.sp,
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

  // ---------------------------------------------------------------- header

  Widget _buildHeader() {
    final waiting = widget.pendingCount - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _pill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5252),
                  shape: BoxShape.circle,
                ),
              ),
              8.horizontalSpace,
              Text(
                'NEW ORDER',
                style: GoogleFonts.poppins(
                  color: AppColors.gold,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          borderColor: AppColors.gold,
          fill: AppColors.gold.withValues(alpha: 0.15),
        ),
        if (waiting > 0)
          _pill(
            child: Text(
              '+$waiting more waiting',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            borderColor: Colors.white24,
            fill: Colors.white.withValues(alpha: 0.10),
          ),
      ],
    );
  }

  Widget _pill({
    required Widget child,
    required Color borderColor,
    required Color fill,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------------ icon

  Widget _buildPulsingIcon() {
    return SizedBox(
      width: 150.w,
      height: 150.w,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          Widget ring(double t) => Transform.scale(
            scale: 1 + t * 0.6,
            child: Opacity(
              opacity: (1 - t) * 0.6,
              child: Container(
                width: 92.w,
                height: 92.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 3),
                ),
              ),
            ),
          );

          return Stack(
            alignment: Alignment.center,
            children: [
              ring(_pulse.value),
              ring((_pulse.value + 0.5) % 1.0),
              Container(
                width: 92.w,
                height: 92.w,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 44.sp,
                  color: AppColors.maroon,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------ card

  Widget _buildCard() {
    final time = order.createdAt != null
        ? DateFormat('h:mm a').format(order.createdAt!)
        : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_flagged) ...[
            _buildWarning(),
            14.verticalSpace,
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'ORDER #${order.id.substring(0, 6).toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              if (time != null)
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          10.verticalSpace,
          _buildPaymentChip(),
          14.verticalSpace,
          const Divider(height: 1),
          14.verticalSpace,
          ...order.items.map(_buildItemRow),
          if (order.items.isNotEmpty) ...[
            6.verticalSpace,
            const Divider(height: 1),
            14.verticalSpace,
          ],
          _buildAddress(),
          14.verticalSpace,
          _buildBill(),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    final note = order.validationNotes.isNotEmpty
        ? order.validationNotes.join(', ')
        : 'Please verify this order before accepting.';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 20.sp),
          8.horizontalSpace,
          Expanded(
            child: Text(
              'Needs review: $note',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip() {
    final isUpi = order.paymentMode == 'upi';
    final color = isUpi ? AppColors.success : AppColors.warning;
    final label = isUpi
        ? 'UPI  •  ${order.paymentStatus.toUpperCase().replaceAll('_', ' ')}'
        : 'CASH ON DELIVERY';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUpi ? Icons.account_balance_wallet_outlined : Icons.payments_outlined,
            size: 16.sp,
            color: color,
          ),
          6.horizontalSpace,
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final qty = (item['qty'] ?? 1) as int;
    final price = ((item['price'] ?? 0) as num).toDouble();
    final isCombo = item['is_combo'] == true;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            constraints: BoxConstraints(minWidth: 36.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.maroon.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '${qty}x',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.maroon,
              ),
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${item['name']}',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (isCombo)
                    TextSpan(
                      text: '  COMBO',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (price > 0)
            Text(
              '₹${(price * qty).toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddress() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, size: 20.sp, color: AppColors.maroon),
          8.horizontalSpace,
          Expanded(
            child: Text(
              order.deliveryAddress,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: AppColors.textDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBill() {
    Widget line(String label, String value, {Color? color}) => Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: color ?? Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );

    final fee = order.deliveryFee;
    return Column(
      children: [
        if (order.itemTotal != null)
          line('Item total', '₹${order.itemTotal!.toStringAsFixed(0)}'),
        if (fee != null)
          line('Delivery fee', fee == 0 ? 'FREE' : '₹${fee.toStringAsFixed(0)}'),
        if (order.couponDiscount > 0)
          line(
            order.couponCode != null && order.couponCode!.isNotEmpty
                ? 'Discount (${order.couponCode})'
                : 'Discount',
            '- ₹${order.couponDiscount.toStringAsFixed(0)}',
            color: AppColors.success,
          ),
        8.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TOTAL AMOUNT',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '₹${order.total.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.maroon,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------- buttons

  Widget _buildAcceptButton() {
    return SizedBox(
      width: double.infinity,
      height: 60.h,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.maroon,
          elevation: 6,
          shadowColor: AppColors.gold.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
        onPressed: widget.onAccept,
        icon: Icon(Icons.check_circle_rounded, size: 24.sp),
        label: Text(
          'ACCEPT & START PREPARING',
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}