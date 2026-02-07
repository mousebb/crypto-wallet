import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PrimaryButtonType {
  primary,
  delete,
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final PrimaryButtonType type;
  final double? width;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = PrimaryButtonType.primary,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? screenHeight * 0.06, // 默认高度为屏幕高度的6%
      child: ElevatedButton(
        onPressed: onPressed,
        style: type == PrimaryButtonType.delete
            ? ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              )
            : AppTheme.getPrimaryButtonStyle(context),
        child: isLoading
            ? SizedBox(
                width: screenWidth * 0.06, // 加载图标宽度为屏幕宽度的6%
                height: screenWidth * 0.06, // 加载图标高度为屏幕宽度的6%
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: type == PrimaryButtonType.delete
                    ? TextStyle(
                        fontSize: screenWidth * 0.04, // 删除按钮文字大小为屏幕宽度的4%
                      )
                    : TextStyle(
                        fontSize: screenWidth * 0.04, // 主要按钮文字大小为屏幕宽度的4%
                        color: Theme.of(context).primaryTextTheme.labelLarge?.color,
                      ),
              ),
      ),
    );
  }
} 