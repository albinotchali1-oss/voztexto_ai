import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  static const _outputDirectoryChannel = MethodChannel(
    'com.example.voztexto_ai/output_directory',
  );
  static const _outputDirectoryPreference = 'converter_output_directory';

  PlatformFile? _selectedFile;
  String? _outputPath;
  String? _outputDirectoryPath;
  bool _isConverting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOutputDirectory();
  }

  Future<void> _loadOutputDirectory() async {
    final preferences = await SharedPreferences.getInstance();
    final savedDirectory = preferences.getString(_outputDirectoryPreference);
    if (!mounted || savedDirectory == null) return;
    setState(() => _outputDirectoryPath = savedDirectory);
  }

  Future<void> _selectVideo() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v'],
      );

      if (file == null) return;

      if (file.path == null) {
        setState(() => _errorMessage = 'Não foi possível acessar o arquivo selecionado.');
        return;
      }

      setState(() {
        _selectedFile = file;
        _outputPath = null;
        _errorMessage = null;
      });
    } catch (error) {
      setState(() => _errorMessage = 'Erro ao selecionar o vídeo: $error');
    }
  }

  Future<void> _convertToAudio() async {
    final inputPath = _selectedFile?.path;
    if (inputPath == null) return;

    setState(() {
      _isConverting = true;
      _outputPath = null;
      _errorMessage = null;
    });

    try {
      final inputName = inputPath.split(Platform.pathSeparator).last;
      final dotIndex = inputName.lastIndexOf('.');
      final baseName = dotIndex > 0 ? inputName.substring(0, dotIndex) : inputName;
      final fileName =
          '${baseName}_${DateTime.now().millisecondsSinceEpoch}.mp3';

      String outputPath;
      if (Platform.isAndroid) {
        if (_outputDirectoryPath == null) {
          await _selectOutputDirectory();
        }
        if (_outputDirectoryPath == null) {
          setState(() {
            _isConverting = false;
            _errorMessage = 'Selecione uma pasta antes de converter.';
          });
          return;
        }

        final documentUri = await _outputDirectoryChannel.invokeMethod<String>(
          'createOutputDocument',
          {'fileName': fileName},
        );
        if (documentUri == null) {
          setState(() {
            _isConverting = false;
            _errorMessage = 'Seleção da pasta de destino cancelada.';
          });
          return;
        }

        final safOutput = await FFmpegKitConfig.getSafParameterForWrite(documentUri);
        if (safOutput == null) {
          throw Exception('Não foi possível preparar a pasta selecionada.');
        }
        outputPath = safOutput;
      } else {
        if (_outputDirectoryPath == null) {
          await _selectOutputDirectory();
        }
        if (_outputDirectoryPath == null) {
          setState(() {
            _isConverting = false;
            _errorMessage = 'Selecione uma pasta antes de converter.';
          });
          return;
        }

        final outputDirectory = Directory(_outputDirectoryPath!);
        if (!await outputDirectory.exists()) {
          await outputDirectory.create(recursive: true);
        }
        outputPath = '${outputDirectory.path}${Platform.pathSeparator}$fileName';
      }

      final session = await FFmpegKit.executeWithArguments([
        '-y',
        '-i',
        inputPath,
        '-vn',
        '-acodec',
        'libmp3lame',
        '-q:a',
        '2',
        outputPath,
      ]);

      final returnCode = await session.getReturnCode();
      if (!mounted) return;

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _outputPath = outputPath;
          _isConverting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Áudio convertido com sucesso!')),
        );
      } else {
        final logs = await session.getLogs();
        final details = logs.isNotEmpty ? logs.last.getMessage() : 'Erro desconhecido.';
        setState(() {
          _isConverting = false;
          _errorMessage = 'Falha na conversão: $details';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isConverting = false;
        _errorMessage = 'Não foi possível converter o vídeo: $error';
      });
    }
  }

  Future<void> _shareOutput() async {
    final outputPath = _outputPath;
    if (outputPath == null) return;

    await SharePlus.instance.share(
      ShareParams(
        text: 'Áudio convertido pelo VozTexto AI',
        files: [XFile(outputPath)],
      ),
    );
  }

  Future<void> _selectOutputDirectory() async {
    try {
      if (Platform.isAndroid) {
        final result = await _outputDirectoryChannel.invokeMethod<String>(
          'pickOutputDirectory',
        );
        if (result == null) return;

        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_outputDirectoryPreference, result);
        setState(() {
          _outputDirectoryPath = result;
          _errorMessage = null;
        });
      } else {
        final directory = await FilePicker.pickDirectory(
          dialogTitle: 'Escolha a pasta para guardar os MP3',
        );
        if (directory == null) return;

        final path = directory.toFilePath();
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_outputDirectoryPreference, path);
        setState(() {
          _outputDirectoryPath = path;
          _errorMessage = null;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Não foi possível selecionar a pasta: $error';
      });
    }
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
            padding: const EdgeInsets.all(28),
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
                const SizedBox(height: 20),
                Text(
                  'Vídeo para áudio',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecione um vídeo e extraia o áudio em formato MP3.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_selectedFile != null) ...[
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
                        const Icon(Icons.video_file_rounded, color: AppColors.teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedFile!.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_isConverting) ...[
                  const LinearProgressIndicator(color: AppColors.teal),
                  const SizedBox(height: 12),
                  const Text(
                    'Convertendo vídeo...',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                ],
                OutlinedButton.icon(
                  onPressed: _isConverting ? null : _selectOutputDirectory,
                  icon: const Icon(Icons.create_new_folder_rounded, size: 19),
                  label: Text(
                    _outputDirectoryPath == null
                        ? 'Escolher pasta de destino'
                        : 'Alterar pasta de destino',
                  ),
                ),
                if (_outputDirectoryPath != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Pasta selecionada',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _outputDirectoryPath!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: _isConverting ? null : _selectVideo,
                  icon: const Icon(Icons.folder_open_rounded, size: 19),
                  label: Text(_selectedFile == null ? 'Selecionar vídeo' : 'Trocar vídeo'),
                ),
                const SizedBox(height: 10),
                if (_selectedFile != null)
                  FilledButton.icon(
                    onPressed: _isConverting ? null : _convertToAudio,
                    icon: const Icon(Icons.autorenew_rounded, size: 19),
                    label: const Text('Converter para MP3'),
                  ),
                if (_outputPath != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _shareOutput,
                    icon: const Icon(Icons.share_rounded, size: 19),
                    label: const Text('Compartilhar MP3'),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: _isConverting ? null : _selectOutputDirectory,
                  icon: const Icon(Icons.save_alt_rounded, size: 19),
                  label: Text(
                    _outputDirectoryPath == null
                        ? 'Selecionar pasta de destino'
                        : 'Pasta de destino selecionada',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}