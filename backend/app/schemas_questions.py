from pydantic import BaseModel, Field, model_validator


class GeneratedQuestion(BaseModel):
    statement: str = Field(min_length=5, max_length=2000)
    options: list[str] = Field(min_length=2, max_length=6)
    correct_index: int = Field(ge=0)
    explanation: str = Field(min_length=1, max_length=2000)

    @model_validator(mode="after")
    def correct_index_must_exist(self) -> "GeneratedQuestion":
        if self.correct_index >= len(self.options):
            raise ValueError("correct_index fora do intervalo de options.")
        if any(not option.strip() for option in self.options):
            raise ValueError("Alternativa vazia.")
        return self


class GenerateQuestionsResponse(BaseModel):
    questions: list[GeneratedQuestion]
