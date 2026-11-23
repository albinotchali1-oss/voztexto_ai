import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit_config.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredAudio {
  const StoredAudio({
    required this.fileName,
    required this.ffmpegPath,
    required this.documentUri,
    required this.folderName,
  });

  final String fileName;
  final String ffmpegPath;
  final String? documentUri;
  final String folderName;
}

class AudioStorageService {
  static const _channel = MethodChannel(
    'com.example.voztexto_ai/output_directory',
  );
  static const _directoryPreference = 'converter_output_directory';
  static const _directoryNamePreference = 'converter_output_directory_name';

  String? _directoryUri;
  String? _directoryPath;
  String? _directoryName;

  String? get directoryName => _directoryName;

  Future<void> loadSavedDirectory() async {
    final preferences = await SharedPreferences.getInstance();
    _directoryUri = preferences.getString(_directoryPreference);
    _directoryPath = preferences.getString(_directoryPreference);
    _directoryName = preferences.getString(_directoryNamePreference);
  }

  Future<bool> chooseOutputDirectory() async {
    if (Platform.isAndroid) {
      final uri = await _channel.invokeMethod<String>('pickOutputDirectory');
      if (uri == null) return false;

      final name = await _channel.invokeMethod<String>('getDirectoryName', {
        'uri': uri,
      });
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_directoryPreference, uri);
      if (name != null) {
        await preferences.setString(_directoryNamePreference, name);
      }
      _directoryUri = uri;
      _directoryPath = null;
      _directoryName = name ?? 'Pasta selecionada';
      return true;
    }

    final directory = await FilePicker.pickDirectory(
      dialogTitle: 'Escolha a pasta para guardar os MP3',
    );
    if (directory == null) return false;

    final path = directory.toFilePath();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_directoryPreference, path);
    await preferences.setString(
      _directoryNamePreference,
      path.split(Platform.pathSeparator).last,
    );
    _directoryPath = path;
    _directoryUri = null;
    _directoryName = path.split(Platform.pathSeparator).last;
    return true;
  }

  Future<StoredAudio?> createOutput(String fileName) async {
    if (_directoryUri == null && _directoryPath == null) {
      await loadSavedDirectory();
    }
    if (_directoryUri == null && _directoryPath == null) {
      final selected = await chooseOutputDirectory();
      if (!selected) return null;
    }

    final directoryUri = _directoryUri;
    if (Platform.isAndroid && directoryUri != null) {
      final documentUri = await _channel.invokeMethod<String>(
        'createOutputDocument',
        {'fileName': fileName},
      );
      if (documentUri == null) return null;
      final outputPath = await FFmpegKitConfig.getSafParameterForWrite(
        documentUri,
      );
      if (outputPath == null) {
        throw Exception('Não foi possível preparar o arquivo de destino.');
      }
      return StoredAudio(
        fileName: fileName,
        ffmpegPath: outputPath,
        documentUri: documentUri,
        folderName: _directoryName ?? 'Pasta selecionada',
      );
    }

    final directoryPath = _directoryPath;
    if (directoryPath == null) return null;
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return StoredAudio(
      fileName: fileName,
      ffmpegPath: '${directory.path}${Platform.pathSeparator}$fileName',
      documentUri: null,
      folderName: _directoryName ?? directory.path,
    );
  }

  Future<void> openAudio(StoredAudio audio) async {
    final uri = audio.documentUri;
    if (Platform.isAndroid && uri != null) {
      await _channel.invokeMethod<void>('openOutputDocument', {'uri': uri});
      return;
    }
    if (audio.ffmpegPath.isNotEmpty) {
      await _channel.invokeMethod<void>('openOutputDocument', {
        'uri': audio.ffmpegPath,
      });
    }
  }
}
