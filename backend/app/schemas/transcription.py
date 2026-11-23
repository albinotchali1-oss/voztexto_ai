from pydantic import BaseModel


class TranscriptionResult(BaseModel):
    success: bool = True
    transcription: str
    language: str
    model: str
