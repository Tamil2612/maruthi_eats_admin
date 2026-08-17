import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.maroon.withValues(alpha: 0.7),
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
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
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
