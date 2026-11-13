from app.core.security import hash_password, verify_password, hash_refresh_token, create_refresh_token


def test_password_is_hashed_and_verified():
    raw = "senha-de-teste-123"
    hashed = hash_password(raw)
    assert raw != hashed
    assert verify_password(raw, hashed)
    assert not verify_password("senha-errada", hashed)


def test_refresh_token_is_random_and_hashed():
    first = create_refresh_token()
    second = create_refresh_token()
    assert first != second
    assert len(hash_refresh_token(first)) == 64
    assert first not in hash_refresh_token(first)
