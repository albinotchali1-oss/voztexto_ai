class TranscriptionResult {
  const TranscriptionResult({
    required this.transcription,
    required this.language,
    required this.model,
  });

  final String transcription;
  final String language;
  final String model;

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      transcription: json['transcription'] as String,
      language: json['language'] as String,
      model: json['model'] as String,
    );
  }
}
