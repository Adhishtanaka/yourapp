import 'package:flutter/material.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/ui/pages/moreDetails.dart';

Widget MoreDetailsWideget(BuildContext context, String path) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(
        top: BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoreDetailsScreen(path: path),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.textOnDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.code_rounded,
                  size: 20,
                  color: AppColors.textOnDark,
                ),
                const SizedBox(width: 8),
                Text(
                  'View Details',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
