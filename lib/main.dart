import 'package:material_ui/material_ui.dart';

import 'core/config/app_theme.dart';
import 'shared/main_navigation.dart';

void main() {
  runApp(const VozTextoApp());
}

class VozTextoApp extends StatelessWidget {
  const VozTextoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VozTexto AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainNavigation(),
    );
  }
}