import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../services/audio_converter_service.dart';
import '../services/audio_storage_service.dart';
import '../services/video_picker_service.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _videoPicker = VideoPickerService();
  final _converter = AudioConverterService();
  final _storage = AudioStorageService();

  SelectedVideo? _video;
  StoredAudio? _audio;
  double? _progress;
  bool _isConverting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _storage.loadSavedDirectory().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _selectVideo() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              subtitle: const Text('Escolher um vídeo da galeria'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Arquivos'),
              subtitle: const Text('Procurar um arquivo MP4 no dispositivo'),
              onTap: () => Navigator.pop(context, 'files'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;

    try {
      final video = source == 'gallery'
          ? await _videoPicker.pickFromGallery()
          : await _videoPicker.pickFromFiles();
      if (!mounted || video == null) return;
      if (!video.name.toLowerCase().endsWith('.mp4')) {
        setState(() => _errorMessage = 'Selecione um vídeo no formato MP4.');
        return;
      }
      setState(() {
        _video = video;
        _audio = null;
        _progress = null;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Não foi possível selecionar o vídeo: $error',
      );
    }
  }

  Future<void> _chooseOutputDirectory() async {
    try {
      final selected = await _storage.chooseOutputDirectory();
      if (!mounted || !selected) return;
      setState(() => _errorMessage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Destino: ${_storage.directoryName}')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Não foi possível escolher a pasta: $error',
      );
    }
  }

  Future<void> _convertVideo() async {
    final video = _video;
    if (video == null || _isConverting) return;

    setState(() {
      _isConverting = true;
      _progress = null;
      _audio = null;
      _errorMessage = null;
    });

    try {
      final dotIndex = video.name.lastIndexOf('.');
      final baseName = dotIndex > 0
          ? video.name.substring(0, dotIndex)
          : video.name;
      final safeBaseName = baseName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final outputName = '${safeBaseName}_audio.mp3';
      final output = await _storage.createOutput(outputName);
      if (output == null) {
        if (mounted) setState(() => _isConverting = false);
        return;
      }

      await _converter.convertMp4ToMp3(
        inputPath: video.path,
        outputPath: output.ffmpegPath,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );

      if (!mounted) return;
      setState(() {
        _audio = output;
        _isConverting = false;
        _progress = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MP3 salvo com sucesso no dispositivo.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isConverting = false;
        _errorMessage = 'Falha ao converter o vídeo: $error';
      });
    }
  }

  Future<void> _openAudio() async {
    final audio = _audio;
    if (audio == null) return;
    try {
      await _storage.openAudio(audio);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o MP3: $error')),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
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
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.teal,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Vídeo para áudio',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Converta MP4 em MP3 diretamente no dispositivo.\n'
                  'O vídeo não é enviado para nenhum servidor.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_video case final video?) ...[
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
                        const Icon(
                          Icons.video_file_rounded,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatSize(video.sizeBytes),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                OutlinedButton.icon(
                  onPressed: _isConverting ? null : _chooseOutputDirectory,
                  icon: const Icon(Icons.folder_open_rounded, size: 19),
                  label: Text(
                    _storage.directoryName == null
                        ? 'Escolher pasta de destino'
                        : 'Destino: ${_storage.directoryName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: _isConverting ? null : _selectVideo,
                  icon: const Icon(Icons.video_library_outlined, size: 19),
                  label: Text(
                    _video == null ? 'Selecionar vídeo MP4' : 'Trocar vídeo',
                  ),
                ),
                if (_video != null) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _isConverting ? null : _convertVideo,
                    icon: const Icon(Icons.autorenew_rounded, size: 19),
                    label: const Text('Converter para MP3'),
                  ),
                ],
                if (_isConverting) ...[
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: _progress,
                    color: AppColors.teal,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _progress == null
                        ? 'Convertendo vídeo...'
                        : 'Convertendo... ${(_progress! * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_audio case final audio?) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conversão concluída',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(audio.fileName),
                        Text(
                          'Salvo em: ${audio.folderName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _openAudio,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Abrir MP3'),
                        ),
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
