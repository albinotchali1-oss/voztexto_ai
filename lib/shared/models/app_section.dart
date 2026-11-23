import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';

/// Secções disponíveis na navegação principal.
enum AppSection {
  home,
  converter,
  transcription,
  translation,
  history;

  String get title => switch (this) {
        AppSection.home => 'Início',
        AppSection.converter => 'Conversor',
        AppSection.transcription => 'Transcrição',
        AppSection.translation => 'Tradução',
        AppSection.history => 'Histórico',
      };

  String get subtitle => switch (this) {
        AppSection.home => 'Seu espaço de áudio e texto',
        AppSection.converter => 'Converta arquivos de áudio e vídeo',
        AppSection.transcription => 'Transforme áudio em texto',
        AppSection.translation => 'Português e inglês',
        AppSection.history => 'Consulte seus trabalhos anteriores',
      };

  String get description => switch (this) {
        AppSection.home => 'Acesse as ferramentas do VozTexto AI.',
        AppSection.converter =>
          'A conversão de arquivos ainda não está disponível nesta versão.',
        AppSection.transcription =>
          'Transcreva áudio online utilizando Groq Whisper Large V3 Turbo.',
        AppSection.translation =>
          'A tradução de textos ainda não está disponível nesta versão.',
        AppSection.history =>
          'O histórico estará disponível quando as ferramentas forem implementadas.',
      };

  IconData get icon => switch (this) {
        AppSection.home => Icons.home_rounded,
        AppSection.converter => Icons.swap_horiz_rounded,
        AppSection.transcription => Icons.graphic_eq_rounded,
        AppSection.translation => Icons.translate_rounded,
        AppSection.history => Icons.history_rounded,
      };

  Color get color => switch (this) {
        AppSection.home => AppColors.teal,
        AppSection.converter => AppColors.teal,
        AppSection.transcription => const Color(0xFF5D65C7),
        AppSection.translation => const Color(0xFFD17A35),
        AppSection.history => const Color(0xFF397EAC),
      };
}