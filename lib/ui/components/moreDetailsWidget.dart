import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/moreDetails.dart';

Widget MoreDetailsWideget(BuildContext context, String path) {
  return Container(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border, width: 1)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => MoreDetailsScreen(path: path),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.code_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Details',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
