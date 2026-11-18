from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient
from google.genai import errors as genai_errors
from google.genai import types

from app.dependencies import get_current_user
from app.main import app
from app.routers.questions import get_question_generator
from app.schemas_questions import GeneratedQuestion
from app.services.question_generator import (
    AINotConfiguredError,
    GeminiQuestionGenerator,
    QuestionGenerationError,
)

PDF = b"%PDF-1.4\n%fake pdf for tests\n"
URL = "/api/v1/questions/generate"


def _question(n_options: int = 4) -> GeneratedQuestion:
    return GeneratedQuestion(
        statement="Qual é a capital do Brasil?",
        options=[f"opção {i}" for i in range(n_options)],
        correct_index=1,
        explanation="Porque sim.",
    )


class FakeGenerator:
    def __init__(self, result=None, error=None):
        self.result, self.error, self.calls = result, error, []

    def generate(self, pdf_bytes, num_questions, num_options):
        self.calls.append((pdf_bytes, num_questions, num_options))
        if self.error:
            raise self.error
        return self.result


@pytest.fixture
def client():
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(id=1, status="active")
    yield TestClient(app)
    app.dependency_overrides.clear()


def _use(generator):
    app.dependency_overrides[get_question_generator] = lambda: generator


def _post(client, content=PDF, **data):
    return client.post(URL, files={"file": ("a.pdf", content)}, data=data)


def test_requires_authentication():
    app.dependency_overrides.clear()
    response = TestClient(app).post(URL, files={"file": ("a.pdf", PDF)})
    assert response.status_code == 401


def test_generates_questions(client):
    fake = FakeGenerator(result=[_question()])
    _use(fake)
    response = _post(client, num_questions="3", num_options="4")
    assert response.status_code == 200
    body = response.json()["questions"][0]
    assert body["correct_index"] == 1 and len(body["options"]) == 4
    assert fake.calls == [(PDF, 3, 4)]


def test_rejects_non_pdf(client):
    _use(FakeGenerator(result=[_question()]))
    assert _post(client, content=b"hello").status_code == 415


def test_rejects_too_large(client, monkeypatch):
    monkeypatch.setattr("app.routers.questions.settings.max_pdf_mb", 0)
    _use(FakeGenerator(result=[_question()]))
    assert _post(client).status_code == 413


@pytest.mark.parametrize("field,value", [("num_questions", "0"), ("num_questions", "21"), ("num_options", "1"), ("num_options", "6")])
def test_rejects_out_of_range_options(client, field, value):
    _use(FakeGenerator(result=[_question()]))
    assert _post(client, **{field: value}).status_code == 422


def test_ai_errors_map_to_status(client):
    _use(FakeGenerator(error=AINotConfiguredError("sem chave")))
    assert _post(client).status_code == 503
    _use(FakeGenerator(error=QuestionGenerationError("falhou")))
    assert _post(client).status_code == 502


def test_generated_question_rejects_bad_index():
    with pytest.raises(ValueError):
        GeneratedQuestion(statement="enunciado", options=["a", "b"], correct_index=2, explanation="x")


def test_parse_validates_shape():
    parse = GeminiQuestionGenerator._parse
    good = '{"questions":[{"statement":"enunciado ok","options":["a","b","c","d"],"correct_index":0,"explanation":"x"}]}'
    assert len(parse(good, 5, 4)) == 1
    with pytest.raises(QuestionGenerationError):
        parse("não é json", 5, 4)
    with pytest.raises(QuestionGenerationError):
        parse(good, 5, 5)  # número de alternativas diferente do pedido
    with pytest.raises(QuestionGenerationError):
        parse('{"questions":[]}', 5, 4)


GOOD_JSON = (
    '{"questions":[{"statement":"enunciado ok","options":["a","b","c","d"],'
    '"correct_index":0,"explanation":"x"}]}'
)


def _settings(key="chave-falsa", fallbacks=""):
    return SimpleNamespace(
        gemini_api_key=key,
        ai_model="gemini-teste",
        ai_fallback_models=fallbacks,
        ai_timeout_seconds=5,
    )


@pytest.fixture(autouse=True)
def _no_sleep(monkeypatch):
    monkeypatch.setattr("app.services.question_generator.time.sleep", lambda _s: None)


class _FakeModels:
    def __init__(self, response=None, error=None):
        self.response, self.error, self.kwargs = response, error, None

    def generate_content(self, **kwargs):
        self.kwargs = kwargs
        if self.error:
            raise self.error
        return self.response


def _patch_client(monkeypatch, models):
    monkeypatch.setattr(
        "app.services.question_generator.genai.Client",
        lambda **_: SimpleNamespace(models=models),
    )


def _response(text, finish=types.FinishReason.STOP):
    return SimpleNamespace(text=text, candidates=[SimpleNamespace(finish_reason=finish)])


def test_gemini_requires_api_key():
    with pytest.raises(AINotConfiguredError):
        GeminiQuestionGenerator(_settings(key=None)).generate(PDF, 1, 4)


def test_gemini_sends_pdf_and_parses_json(monkeypatch):
    models = _FakeModels(response=_response(GOOD_JSON))
    _patch_client(monkeypatch, models)
    questions = GeminiQuestionGenerator(_settings()).generate(PDF, 5, 4)
    assert len(questions) == 1 and questions[0].correct_index == 0
    assert models.kwargs["model"] == "gemini-teste"
    pdf_part = models.kwargs["contents"][0]
    assert pdf_part.inline_data.mime_type == "application/pdf"
    assert pdf_part.inline_data.data == PDF
    assert models.kwargs["config"].response_mime_type == "application/json"


def test_gemini_truncated_or_empty_answer_fails(monkeypatch):
    _patch_client(monkeypatch, _FakeModels(response=_response(GOOD_JSON, types.FinishReason.MAX_TOKENS)))
    with pytest.raises(QuestionGenerationError):
        GeminiQuestionGenerator(_settings()).generate(PDF, 1, 4)
    _patch_client(monkeypatch, _FakeModels(response=_response(None)))
    with pytest.raises(QuestionGenerationError):
        GeminiQuestionGenerator(_settings()).generate(PDF, 1, 4)


@pytest.mark.parametrize("code,fragment", [(429, "limite de uso"), (500, "não respondeu")])
def test_gemini_api_errors_become_friendly_messages(monkeypatch, code, fragment):
    error = genai_errors.APIError(code, {"error": {"message": "x", "status": "X"}})
    _patch_client(monkeypatch, _FakeModels(error=error))
    with pytest.raises(QuestionGenerationError) as info:
        GeminiQuestionGenerator(_settings()).generate(PDF, 1, 4)
    assert fragment in str(info.value)


def _api_error(code):
    return genai_errors.APIError(code, {"error": {"message": "x", "status": "X"}})


class _ScriptedModels:
    """Responde por modelo, em ordem: cada item é uma resposta ou um erro."""

    def __init__(self, script):
        self.script, self.calls = script, []

    def generate_content(self, **kwargs):
        model = kwargs["model"]
        self.calls.append(model)
        item = self.script[model].pop(0)
        if isinstance(item, Exception):
            raise item
        return item


def test_gemini_retries_503_on_same_model(monkeypatch):
    models = _ScriptedModels({"gemini-teste": [_api_error(503), _response(GOOD_JSON)]})
    _patch_client(monkeypatch, models)
    assert len(GeminiQuestionGenerator(_settings()).generate(PDF, 1, 4)) == 1
    assert models.calls == ["gemini-teste", "gemini-teste"]


def test_gemini_falls_back_to_next_model(monkeypatch):
    models = _ScriptedModels(
        {
            "gemini-teste": [_api_error(503), _api_error(503)],
            "reserva-1": [_api_error(404)],
            "reserva-2": [_response(GOOD_JSON)],
        }
    )
    _patch_client(monkeypatch, models)
    generator = GeminiQuestionGenerator(_settings(fallbacks="reserva-1, reserva-2,reserva-2"))
    assert len(generator.generate(PDF, 1, 4)) == 1
    assert models.calls == ["gemini-teste", "gemini-teste", "reserva-1", "reserva-2"]


def test_gemini_all_models_fail(monkeypatch):
    models = _ScriptedModels({"gemini-teste": [_api_error(503), _api_error(503)], "r": [_api_error(429)]})
    _patch_client(monkeypatch, models)
    with pytest.raises(QuestionGenerationError) as info:
        GeminiQuestionGenerator(_settings(fallbacks="r")).generate(PDF, 1, 4)
    assert "limite de uso" in str(info.value)


def test_gemini_bad_request_does_not_try_other_models(monkeypatch):
    models = _ScriptedModels({"gemini-teste": [_api_error(400)], "r": [_response(GOOD_JSON)]})
    _patch_client(monkeypatch, models)
    with pytest.raises(QuestionGenerationError):
        GeminiQuestionGenerator(_settings(fallbacks="r")).generate(PDF, 1, 4)
    assert models.calls == ["gemini-teste"]


def test_gemini_network_failure_is_friendly(monkeypatch):
    _patch_client(monkeypatch, _FakeModels(error=TimeoutError("lento")))
    with pytest.raises(QuestionGenerationError):
        GeminiQuestionGenerator(_settings()).generate(PDF, 1, 4)
