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
    settings = Settings(
        _env_file=None,
        environment="test",
        jwt_secret_key="test-secret-with-at-least-32-characters",
    )
    assert settings.database_url == "sqlite:///./app.db"

    settings = make_settings(database_url="postgresql://localhost/database")
    assert settings.database_url == "postgresql+psycopg://localhost/database"


def test_database_url_falls_back_to_sqlite_for_non_production_environments(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    settings = Settings(
        _env_file=None,
        environment="development",
        jwt_secret_key="test-secret-with-at-least-32-characters",
    )
    assert settings.database_url == "sqlite:///./app.db"


def test_database_url_is_required_in_production_when_missing_or_blank():
    for database_url in (None, ""):
        with pytest.raises(ValidationError, match="DATABASE_URL is required"):
            Settings(
                _env_file=None,
                environment="production",
                database_url=database_url,
                jwt_secret_key="test-secret-with-at-least-32-characters",
            )


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
