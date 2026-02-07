# Localization Setup with easy_localization

This directory contains the translation files for the Crypto Wallet app. The app uses the [easy_localization](https://pub.dev/packages/easy_localization) package for handling translations.

## Translation Files

- `zh.json`: Chinese translations
- `en.json`: English translations

## Integration Steps

1. Add the easy_localization package to your `pubspec.yaml`:

```yaml
dependencies:
  easy_localization: ^3.0.0
```

2. Update your `main.dart` file to initialize easy_localization:

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('zh'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // ... rest of your app configuration
    );
  }
}
```

3. Update your `pubspec.yaml` to include the translation files:

```yaml
flutter:
  assets:
    - assets/translations/
```

## Using Translations in Your Code

1. Import the easy_localization package:

```dart
import 'package:easy_localization/easy_localization.dart';
```

2. Use the translation keys in your widgets:

```dart
Text('profile.title'.tr())
```

3. For translations with parameters:

```dart
Text('profile.language_selected'.tr(args: ['English']))
```

4. To change the language programmatically:

```dart
context.setLocale(const Locale('en'));
```

## Adding New Translations

1. Add new keys to both `zh.json` and `en.json` files
2. Follow the nested structure for organizing translations
3. Use the same keys in both files to ensure consistency

## Example

```dart
// Before
Text('我的')

// After
Text('profile.title'.tr())
```

See `lib/localization_example.dart` for a complete example of how to use translations in your app. 