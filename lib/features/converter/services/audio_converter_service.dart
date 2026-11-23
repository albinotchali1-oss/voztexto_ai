import 'dart:async';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';

class AudioConverterService {
  Future<void> convertMp4ToMp3({
    required String inputPath,
    required String outputPath,
    required void Function(double? progress) onProgress,
  }) async {
    final informationSession = await FFprobeKit.getMediaInformation(inputPath);
    final durationSeconds = double.tryParse(
      informationSession.getMediaInformation()?.getDuration() ?? '',
    );

    final completed = Completer<dynamic>();
    await FFmpegKit.executeWithArgumentsAsync(
      [
        '-y',
        '-i',
        inputPath,
        '-vn',
        '-c:a',
        'libmp3lame',
        '-b:a',
        '192k',
        outputPath,
      ],
      (session) {
        if (!completed.isCompleted) completed.complete(session);
      },
      null,
      (statistics) {
        final duration = durationSeconds;
        final progress = duration != null && duration > 0
            ? (statistics.getTime() / 1000 / duration).clamp(0.0, 1.0)
            : null;
        onProgress(progress);
      },
    );

    final session = await completed.future;
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      onProgress(1);
      return;
    }

    final logs = await session.getLogs();
    final details = logs.isNotEmpty
        ? logs.last.getMessage()
        : 'Sem detalhes disponíveis.';
    throw Exception('A conversão falhou. $details');
  }
}
