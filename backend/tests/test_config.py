import pytest
from pydantic import ValidationError

from app.config import Settings


def make_settings(**overrides):
    values = {
        "_env_file": None,
        "database_url": "sqlite:///:memory:",
        "jwt_secret_key": "test-secret-with-at-least-32-characters",
    }
    values.update(overrides)
    return Settings(**values)


def test_jwt_secret_must_be_configured_and_long_enough():
    with pytest.raises(ValidationError):
        make_settings(jwt_secret_key="")

    with pytest.raises(ValidationError):
        make_settings(jwt_secret_key="too-short")

    with pytest.raises(ValidationError):
        make_settings(jwt_expire_minutes=0)


def test_database_url_is_required_and_postgres_urls_are_normalized(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    with pytest.raises(ValidationError):
        Settings(_env_file=None, jwt_secret_key="test-secret-with-at-least-32-characters")

    settings = make_settings(database_url="postgresql://user:password@localhost/database")
    assert settings.database_url == "postgresql+psycopg://user:password@localhost/database"


def test_cors_accepts_exact_https_and_local_origins():
    settings = make_settings(
        cors_origins=" https://frontend.test/ , http://localhost:5173,https://frontend.test "
    )

    assert settings.allowed_cors_origins == [
        "https://frontend.test",
        "http://localhost:5173",
    ]


def test_cors_defaults_to_no_origins():
    settings = make_settings(cors_origins="")

    assert settings.allowed_cors_origins == []


@pytest.mark.parametrize(
    "origins",
    [
        "*",
        "https://frontend.test/path",
        "http://frontend.test",
        "http://api.railway.app",
        "http://api.up.railway.app",
        "https://user@frontend.test",
        "https://frontend.test:invalid",
        "https://frontend.test:",
    ],
)
def test_cors_rejects_wildcards_and_non_origin_urls(origins):
    with pytest.raises(ValidationError):
        make_settings(cors_origins=origins)
