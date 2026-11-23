import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class SelectedVideo {
  const SelectedVideo({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int sizeBytes;
}

class VideoPickerService {
  VideoPickerService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<SelectedVideo?> pickFromGallery() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video == null) return null;

    return SelectedVideo(
      path: video.path,
      name: video.name,
      sizeBytes: await video.length(),
    );
  }

  Future<SelectedVideo?> pickFromFiles() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['mp4'],
    );
    if (result == null) return null;

    final path = result.path;
    if (path == null) {
      throw Exception('Não foi possível acessar o vídeo selecionado.');
    }

    return SelectedVideo(
      path: path,
      name: result.name,
      sizeBytes: await File(path).length(),
    );
  }
}
