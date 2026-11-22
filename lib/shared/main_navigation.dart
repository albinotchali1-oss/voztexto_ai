import 'package:material_ui/material_ui.dart';

import '../core/constants/app_colors.dart';
import '../features/converter/presentation/converter_page.dart';
import '../features/history/presentation/history_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/transcription/presentation/transcription_page.dart';
import '../features/translation/presentation/translation_page.dart';
import 'models/app_section.dart';

/// Casca principal que mantém as secções acessíveis pela navegação inferior.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<AppSection> _sections = AppSection.values;

  late final List<Widget> _pages = [
    HomePage(onOpenSection: _openSection),
    const ConverterPage(),
    const TranscriptionPage(),
    const TranslationPage(),
    const HistoryPage(),
  ];

  void _openSection(AppSection section) {
    setState(() => _selectedIndex = _sections.indexOf(section));
  }

  @override
  Widget build(BuildContext context) {
    final selectedSection = _sections[_selectedIndex];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: Text(selectedSection.title),
              backgroundColor: AppColors.canvas,
              foregroundColor: AppColors.ink,
              elevation: 0,
            ),
      body: SafeArea(
        top: _selectedIndex == 0,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          for (final section in _sections)
            NavigationDestination(
              icon: Icon(section.icon),
              label: section.title,
              tooltip: section.title,
            ),
        ],
      ),
    );
  }
}