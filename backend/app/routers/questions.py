from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.concurrency import run_in_threadpool

from app.core.config import get_settings
from app.dependencies import get_current_user
from app.models import User
from app.schemas_questions import GenerateQuestionsResponse
from app.services.question_generator import (
    AINotConfiguredError,
    GeminiQuestionGenerator,
    QuestionGenerationError,
    QuestionGenerator,
)

router = APIRouter(prefix="/questions", tags=["Questões"])
settings = get_settings()

_CHUNK = 1024 * 1024


def get_question_generator() -> QuestionGenerator:
    return GeminiQuestionGenerator(settings)


async def _read_pdf(file: UploadFile) -> bytes:
    limit = settings.max_pdf_mb * 1024 * 1024
    data = bytearray()
    while chunk := await file.read(_CHUNK):
        data.extend(chunk)
        if len(data) > limit:
            raise HTTPException(
                status_code=413, detail=f"O PDF excede o limite de {settings.max_pdf_mb} MB."
            )
    if not data.startswith(b"%PDF-"):
        raise HTTPException(status_code=415, detail="Envie um arquivo PDF válido.")
    return bytes(data)


@router.post("/generate", response_model=GenerateQuestionsResponse)
async def generate_questions(
    file: UploadFile = File(...),
    num_questions: int = Form(5, ge=1, le=20),
    num_options: int = Form(4, ge=2, le=5),
    _user: User = Depends(get_current_user),
    generator: QuestionGenerator = Depends(get_question_generator),
):
    pdf_bytes = await _read_pdf(file)
    try:
        # A chamada à IA é bloqueante; roda fora do loop de eventos.
        questions = await run_in_threadpool(generator.generate, pdf_bytes, num_questions, num_options)
    except AINotConfiguredError as exc:
        raise HTTPException(status_code=503, detail=str(exc))
    except QuestionGenerationError as exc:
        raise HTTPException(status_code=502, detail=str(exc))
    return GenerateQuestionsResponse(questions=questions)
