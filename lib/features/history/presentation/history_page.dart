import 'package:material_ui/material_ui.dart';

import '../../../shared/models/app_section.dart';
import '../../../shared/widgets/feature_placeholder_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholderPage(
        section: AppSection.history,
      );
}