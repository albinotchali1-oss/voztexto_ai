import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';
import '../services/transcription_service.dart';

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  final _transcriptionService = TranscriptionService();
  File? _selectedFile;
  String _language = 'pt';
  String? _transcription;
  String? _errorMessage;
  bool _isTranscribing = false;

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['flac', 'mp3', 'mp4', 'mpeg', 'mpga', 'm4a', 'ogg', 'wav', 'webm'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _selectedFile = File(result.files.single.path!);
      _transcription = null;
      _errorMessage = null;
    });
  }

  Future<void> _transcribe() async {
    final file = _selectedFile;
    if (file == null || _isTranscribing) return;

    setState(() {
      _isTranscribing = true;
      _transcription = null;
      _errorMessage = null;
    });

    try {
      final result = await _transcriptionService.transcribe(
        file: file,
        language: _language,
      );
      if (!mounted) return;
      setState(() {
        _transcription = result.transcription;
        _isTranscribing = false;
      });
    } on TranscriptionException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isTranscribing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível concluir a transcrição.';
        _isTranscribing = false;
      });
    }
  }

  String _formatSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEEF9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF5D65C7), size: 32),
                ),
                const SizedBox(height: 18),
                Text('Transcrever áudio', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Envie um áudio ao backend para transcrição online pelo Groq.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'pt', label: Text('Português')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {_language},
                  onSelectionChanged: _isTranscribing
                      ? null
                      : (values) => setState(() {
                            _language = values.first;
                            _transcription = null;
                          }),
                ),
                const SizedBox(height: 14),
                if (_selectedFile case final file?)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.audio_file_rounded, color: Color(0xFF5D65C7)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(file.path.split(Platform.pathSeparator).last, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(_formatSize(file), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _isTranscribing ? null : _selectFile,
                  icon: const Icon(Icons.folder_open_rounded, size: 19),
                  label: Text(_selectedFile == null ? 'Selecionar ficheiro de áudio' : 'Trocar ficheiro'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _selectedFile == null || _isTranscribing ? null : _transcribe,
                  icon: const Icon(Icons.transcribe_rounded, size: 19),
                  label: const Text('Transcrever'),
                ),
                if (_isTranscribing) ...[
                  const SizedBox(height: 18),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('A enviar e transcrever o áudio...', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                ],
                if (_transcription != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transcrição', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        SelectableText(_transcription!, style: const TextStyle(color: AppColors.ink, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
