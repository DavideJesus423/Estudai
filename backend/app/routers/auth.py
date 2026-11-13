import hmac
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import (
    create_access_token, create_refresh_token, hash_password,
    hash_refresh_token, refresh_expiration, verify_password,
)
from app.db import get_db
from app.dependencies import get_current_user
from app.models import User, UserSession
from app.schemas import LoginRequest, RefreshRequest, RegisterRequest, TokenResponse, UserResponse

router = APIRouter(prefix="/auth", tags=["Autenticação"])
settings = get_settings()


def _issue_session(db: Session, user: User) -> TokenResponse:
    refresh = create_refresh_token()
    session = UserSession(
        user_id=user.id,
        refresh_token_hash=hash_refresh_token(refresh),
        expires_at=refresh_expiration(),
    )
    db.add(session)
    db.commit()
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=refresh,
        expires_in=settings.access_token_minutes * 60,
        user=UserResponse.model_validate(user),
    )


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    email = str(payload.email).strip().lower()
    existing = db.scalar(select(User.id).where(User.email == email))
    if existing is not None:
        raise HTTPException(status_code=409, detail="Não foi possível criar a conta com esses dados.")

    user = User(
        name=payload.name,
        email=email,
        password_hash=hash_password(payload.password),
        status="active",
    )
    db.add(user)
    try:
        db.flush()
        result = _issue_session(db, user)
        return result
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Não foi possível criar a conta com esses dados.")
    except Exception:
        db.rollback()
        raise


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    email = str(payload.email).strip().lower()
    user = db.scalar(select(User).where(User.email == email))
    # Mensagem igual para e-mail inexistente e senha incorreta evita revelar contas.
    if user is None or user.password_hash is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos.")
    if user.status != "active":
        raise HTTPException(status_code=403, detail="Esta conta não está disponível para acesso.")
    return _issue_session(db, user)


@router.post("/refresh", response_model=TokenResponse)
def refresh(payload: RefreshRequest, db: Session = Depends(get_db)):
    token_hash = hash_refresh_token(payload.refresh_token)
    session = db.scalar(
        select(UserSession)
        .where(UserSession.refresh_token_hash == token_hash)
        .with_for_update()
    )
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if session is None or session.revoked_at is not None or session.expires_at <= now:
        raise HTTPException(status_code=401, detail="Sessão expirada ou inválida.")

    user = db.get(User, session.user_id)
    if user is None or user.status != "active":
        session.revoked_at = now
        db.commit()
        raise HTTPException(status_code=401, detail="Sessão expirada ou inválida.")

    # Rotação: o token antigo deixa de funcionar antes de emitir o novo.
    session.revoked_at = now
    db.flush()
    result = _issue_session(db, user)
    return result


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(payload: RefreshRequest, db: Session = Depends(get_db)):
    session = db.scalar(
        select(UserSession).where(
            UserSession.refresh_token_hash == hash_refresh_token(payload.refresh_token)
        )
    )
    if session is not None and session.revoked_at is None:
        session.revoked_at = datetime.now(timezone.utc).replace(tzinfo=None)
        db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/me", response_model=UserResponse)
def me(user: User = Depends(get_current_user)):
    return user
