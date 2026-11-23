import 'dart:convert';
import 'dart:io';

import '../models/transcription_result.dart';

class TranscriptionException implements Exception {
  const TranscriptionException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class TranscriptionService {
  TranscriptionService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'VOZTEXTO_API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            );

  final String baseUrl;

  Future<TranscriptionResult> transcribe({
    required File file,
    required String language,
  }) async {
    final uri = Uri.parse('$baseUrl/api/transcriptions');
    final request = await HttpClient().postUrl(uri);

    final boundary = 'voztexto-${DateTime.now().microsecondsSinceEpoch}';
    request.headers.set(HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary');

    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileBytes = await file.readAsBytes();

    final body = BytesBuilder(copy: false);
    void addText(String name, String value) {
      body.add(utf8.encode('--$boundary\r\n'));
      body.add(utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'));
      body.add(utf8.encode('$value\r\n'));
    }

    addText('language', language);
    body.add(utf8.encode('--$boundary\r\n'));
    body.add(utf8.encode(
        'Content-Disposition: form-data; name="file"; filename="$fileName"\r\n'));
    body.add(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
    body.add(fileBytes);
    body.add(utf8.encode('\r\n--$boundary--\r\n'));

    request.contentLength = body.length;
    request.add(body.takeBytes());

    HttpClientResponse response;
    try {
      response = await request.close();
    } on SocketException {
      throw const TranscriptionException(
        'Não foi possível conectar ao backend. Verifique o endereço e a rede.',
        code: 'connection_error',
      );
    }

    final responseText = await response.transform(utf8.decoder).join();
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(responseText) as Map<String, dynamic>;
    } catch (_) {
      throw TranscriptionException(
        'O servidor respondeu em formato inválido.',
        code: 'invalid_response',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return TranscriptionResult.fromJson(payload);
    }

    final detail = payload['detail'];
    final code = detail is Map ? detail['code'] as String? : null;
    final message = detail is Map
        ? detail['message'] as String?
        : payload['message'] as String?;

    if (response.statusCode == 429 || code == 'free_limit_reached') {
      throw TranscriptionException(
        message ??
            'O limite gratuito da Groq foi atingido. Aguarde a renovação antes de tentar novamente.',
        code: 'free_limit_reached',
      );
    }

    throw TranscriptionException(
      message ?? 'Não foi possível concluir a transcrição.',
      code: code,
    );
  }
}
