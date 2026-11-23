import io
import os

from groq import Groq


MODEL = "whisper-large-v3-turbo"


class GroqFreeLimitError(Exception):
    pass


class GroqAuthenticationError(Exception):
    pass


class GroqUnavailableError(Exception):
    pass


class GroqRequestError(Exception):
    pass


class GroqService:
    def __init__(self) -> None:
        api_key = os.getenv("GROQ_API_KEY", "").strip()
        if not api_key:
            raise RuntimeError("GROQ_API_KEY não está configurada.")
        self._client = Groq(api_key=api_key)

    def transcribe(self, file_name: str, file_bytes: bytes, language: str) -> str:
        try:
            result = self._client.audio.transcriptions.create(
                file=(file_name, io.BytesIO(file_bytes)),
                model=MODEL,
                language=language,
                response_format="json",
            )
            text = getattr(result, "text", None)
            if not isinstance(text, str):
                raise GroqRequestError("A resposta da Groq não continha texto válido.")
            return text
        except Exception as exc:
            status_code = getattr(exc, "status_code", None)
            if status_code == 429:
                raise GroqFreeLimitError(
                    "O limite gratuito da Groq foi atingido. Aguarde a renovação do limite antes de tentar novamente."
                ) from exc
            if status_code in (401, 403):
                raise GroqAuthenticationError(
                    "A autenticação da Groq falhou. Verifique a chave configurada no servidor."
                ) from exc
            if status_code is not None and 500 <= status_code < 600:
                raise GroqUnavailableError(
                    "O serviço Groq está temporariamente indisponível. Tente novamente mais tarde."
                ) from exc
            if isinstance(exc, GroqFreeLimitError) or isinstance(exc, GroqAuthenticationError) or isinstance(exc, GroqUnavailableError):
                raise
            raise GroqRequestError("Não foi possível comunicar com o serviço Groq.") from exc
