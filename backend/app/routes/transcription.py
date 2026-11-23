from pathlib import Path

from fastapi import HTTPException, UploadFile

from ..schemas.transcription import TranscriptionResult
from ..services.groq_service import (
    GroqAuthenticationError,
    GroqFreeLimitError,
    GroqRequestError,
    GroqUnavailableError,
    GroqService,
    MODEL,
)


MAX_FILE_SIZE = 25 * 1024 * 1024
SUPPORTED_EXTENSIONS = {".flac", ".mp3", ".mp4", ".mpeg", ".mpga", ".m4a", ".ogg", ".wav", ".webm"}
SUPPORTED_LANGUAGES = {"pt", "en"}


def validate_language(language: str) -> str:
    normalized = language.strip().lower()
    if normalized not in SUPPORTED_LANGUAGES:
        raise HTTPException(
            status_code=400,
            detail={
                "code": "unsupported_language",
                "message": "Idioma não suportado. Utilize pt ou en.",
            },
        )
    return normalized


async def create_transcription(file: UploadFile, language: str = "pt") -> TranscriptionResult:
    selected_language = validate_language(language)

    if not file.filename:
        raise HTTPException(status_code=400, detail={"code": "missing_file_name", "message": "O ficheiro deve possuir um nome."})

    extension = Path(file.filename).suffix.lower()
    if extension not in SUPPORTED_EXTENSIONS:
        raise HTTPException(status_code=415, detail={"code": "unsupported_file_format", "message": "Formato de áudio não suportado."})

    content = await file.read(MAX_FILE_SIZE + 1)
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail={"code": "file_too_large", "message": "O ficheiro excede o limite de 25 MB."})
    if not content:
        raise HTTPException(status_code=400, detail={"code": "empty_file", "message": "O ficheiro enviado está vazio."})

    try:
        transcription = GroqService().transcribe(file.filename, content, selected_language)
    except GroqFreeLimitError as exc:
        raise HTTPException(status_code=429, detail={"code": "free_limit_reached", "message": str(exc)}) from exc
    except GroqAuthenticationError as exc:
        raise HTTPException(status_code=502, detail={"code": "provider_authentication_error", "message": "Falha de autenticação com o serviço de transcrição."}) from exc
    except GroqUnavailableError as exc:
        raise HTTPException(status_code=503, detail={"code": "provider_unavailable", "message": str(exc)}) from exc
    except GroqRequestError as exc:
        raise HTTPException(status_code=502, detail={"code": "provider_request_failed", "message": "Não foi possível concluir a transcrição neste momento."}) from exc

    return TranscriptionResult(
        transcription=transcription,
        language=selected_language,
        model=MODEL,
    )
