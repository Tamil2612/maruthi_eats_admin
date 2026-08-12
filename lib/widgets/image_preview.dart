import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

class ImagePreview extends StatelessWidget {
  final String? imageUrl;
  final double height;

  const ImagePreview({
    super.key,
    this.imageUrl,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      height: height.h,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.maroon.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: hasUrl
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(
                  icon: Icons.broken_image_outlined,
                  text: 'Could not load image',
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
                },
              )
            : _buildPlaceholder(
                icon: Icons.image_outlined,
                text: 'Image Preview',
              ),
      ),
    );
  }

  Widget _buildPlaceholder({required IconData icon, required String text}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40.sp, color: AppColors.maroon.withOpacity(0.3)),
        8.verticalSpace,
        Text(
          text,
          style: TextStyle(
            color: AppColors.maroon.withOpacity(0.4),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
