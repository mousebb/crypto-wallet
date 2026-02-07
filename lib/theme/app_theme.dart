import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

class AppTheme {
  // Common styles for containers
  static BoxDecoration getContainerDecoration(BuildContext context, {double borderRadius = 12}) {
    return BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.grey[200],
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // Common styles for text fields
  static InputDecoration getTextFieldDecoration(BuildContext context, {String? hintText}) {
    return InputDecoration(
      border: InputBorder.none,
      hintText: hintText,
      hintStyle: TextStyle(
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      isDense: true,
      alignLabelWithHint: true,
    );
  }

  // Common styles for buttons
  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[300],
      disabledForegroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]
          : Colors.grey[500],
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Common styles for outlined buttons
  static ButtonStyle getOutlinedButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      side: BorderSide(color: Theme.of(context).primaryColor),
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Common styles for text buttons
  static ButtonStyle getTextButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: Theme.of(context).primaryColor,
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Common styles for app bars
  static AppBarTheme getAppBarTheme(BuildContext context) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(
        color: Theme.of(context).iconTheme.color,
      ),
      titleTextStyle: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.045,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  // Common styles for snackbars
  static SnackBarThemeData getSnackBarTheme(BuildContext context) {
    return SnackBarThemeData(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
      contentTextStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Common styles for checkboxes
  static CheckboxThemeData getCheckboxTheme(BuildContext context) {
    return CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey;
        }
        return Theme.of(context).primaryColor;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // Common styles for list tiles
  static ListTileThemeData getListTileTheme(BuildContext context) {
    return ListTileThemeData(
      textColor: Theme.of(context).textTheme.bodyMedium?.color,
      iconColor: Theme.of(context).iconTheme.color,
      tileColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Common styles for cards
  static CardTheme getCardTheme(BuildContext context) {
    return CardTheme(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // Common styles for dividers
  static DividerThemeData getDividerTheme(BuildContext context) {
    return DividerThemeData(
      color: Theme.of(context).dividerColor,
      thickness: 1,
      space: 16,
    );
  }

  // Common styles for tooltips
  static TooltipThemeData getTooltipTheme(BuildContext context) {
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
    );
  }

  // Common styles for bottom sheets
  static BottomSheetThemeData getBottomSheetTheme(BuildContext context) {
    return BottomSheetThemeData(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
    );
  }

  // Common styles for dialogs
  static DialogTheme getDialogTheme(BuildContext context) {
    return DialogTheme(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: Theme.of(context).textTheme.titleLarge,
      contentTextStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }

  // Common styles for bottom navigation bar
  static BottomNavigationBarThemeData getBottomNavigationBarTheme(BuildContext context) {
    return BottomNavigationBarThemeData(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]
          : Colors.grey[400],
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Common styles for tab bar
  static TabBarTheme getTabBarTheme(BuildContext context) {
    return TabBarTheme(
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]
          : Colors.grey[400],
      indicatorColor: Theme.of(context).primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Common styles for progress indicators
  static ProgressIndicatorThemeData getProgressIndicatorTheme(BuildContext context) {
    return ProgressIndicatorThemeData(
      color: Theme.of(context).primaryColor,
      circularTrackColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
      linearTrackColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
    );
  }

  // Common styles for switches
  static SwitchThemeData getSwitchTheme(BuildContext context) {
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey;
        }
        return Theme.of(context).primaryColor;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey.withOpacity(0.5);
        }
        return Theme.of(context).primaryColor.withOpacity(0.5);
      }),
    );
  }

  // Common styles for radio buttons
  static RadioThemeData getRadioTheme(BuildContext context) {
    return RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey;
        }
        return Theme.of(context).primaryColor;
      }),
    );
  }

  // Common styles for sliders
  static SliderThemeData getSliderTheme(BuildContext context) {
    return SliderThemeData(
      activeTrackColor: Theme.of(context).primaryColor,
      inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.3),
      thumbColor: Theme.of(context).primaryColor,
      overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  // Common styles for text selection
  static TextSelectionThemeData getTextSelectionTheme(BuildContext context) {
    return TextSelectionThemeData(
      cursorColor: Theme.of(context).primaryColor,
      selectionColor: Theme.of(context).primaryColor.withOpacity(0.3),
      selectionHandleColor: Theme.of(context).primaryColor,
    );
  }

  // Common styles for input decoration
  static InputDecorationTheme getInputDecorationTheme(BuildContext context) {
    return InputDecorationTheme(
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      hintStyle: TextStyle(
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    );
  }

  // Common styles for elevated buttons
  static ElevatedButtonThemeData getElevatedButtonTheme(BuildContext context) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Common styles for outlined buttons
  static OutlinedButtonThemeData getOutlinedButtonTheme(BuildContext context) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Common styles for text buttons
  static TextButtonThemeData getTextButtonTheme(BuildContext context) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Common styles for icon buttons
  static IconButtonThemeData getIconButtonTheme(BuildContext context) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: Theme.of(context).iconTheme.color,
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
      ),
    );
  }

  // Common styles for icon theme
  static IconThemeData getIconTheme(BuildContext context) {
    return IconThemeData(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87,
      size: 24,
    );
  }

  // Common styles for text theme
  static TextTheme getTextTheme(BuildContext context) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.08,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      displayMedium: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.07,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      displaySmall: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.06,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      headlineMedium: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.05,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      titleLarge: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.045,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      titleMedium: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.04,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      bodyLarge: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.04,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.035,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      bodySmall: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.03,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : Colors.black54,
      ),
    );
  }

  // Common styles for color scheme
  static ColorScheme getColorScheme(BuildContext context) {
    return ColorScheme(
      brightness: Theme.of(context).brightness,
      primary: Theme.of(context).primaryColor,
      onPrimary: Colors.white,
      secondary: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[300]!
          : Colors.grey[700]!,
      onSecondary: Theme.of(context).brightness == Brightness.dark
          ? Colors.black87
          : Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Theme.of(context).scaffoldBackgroundColor,
      onBackground: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87,
      surface: Theme.of(context).cardColor,
      onSurface: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87,
    );
  }

  // Create a complete theme data object
  static ThemeData createTheme(BuildContext context, {bool isDark = false}) {
    final colorScheme = getColorScheme(context);
    final textTheme = getTextTheme(context);
    final iconTheme = getIconTheme(context);
    
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.grey[50],
      cardColor: isDark ? Colors.grey[900] : Colors.white,
      dividerColor: isDark ? Colors.grey[800] : Colors.grey[300],
      iconTheme: iconTheme,
      textTheme: textTheme,
      appBarTheme: getAppBarTheme(context),
      snackBarTheme: getSnackBarTheme(context),
      checkboxTheme: getCheckboxTheme(context),
      listTileTheme: getListTileTheme(context),
      cardTheme: getCardTheme(context),
      dividerTheme: getDividerTheme(context),
      tooltipTheme: getTooltipTheme(context),
      bottomSheetTheme: getBottomSheetTheme(context),
      dialogTheme: getDialogTheme(context),
      bottomNavigationBarTheme: getBottomNavigationBarTheme(context),
      tabBarTheme: getTabBarTheme(context),
      progressIndicatorTheme: getProgressIndicatorTheme(context),
      switchTheme: getSwitchTheme(context),
      radioTheme: getRadioTheme(context),
      sliderTheme: getSliderTheme(context),
      textSelectionTheme: getTextSelectionTheme(context),
      inputDecorationTheme: getInputDecorationTheme(context),
      elevatedButtonTheme: getElevatedButtonTheme(context),
      outlinedButtonTheme: getOutlinedButtonTheme(context),
      textButtonTheme: getTextButtonTheme(context),
      iconButtonTheme: getIconButtonTheme(context),
    );
  }

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF2196F3),
      secondary: const Color(0xFF4CAF50),
      surface: Colors.white,
      background: Colors.grey[50]!,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey[50],
    cardColor: Colors.white,
    dividerColor: Colors.grey[300],
    iconTheme: const IconThemeData(
      color: Colors.black87,
      size: 24,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2196F3)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF2196F3),
      secondary: const Color(0xFF4CAF50),
      surface: Colors.grey[900]!,
      background: Colors.black,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey[900],
    dividerColor: Colors.grey[800],
    iconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.white70,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2196F3)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
} 