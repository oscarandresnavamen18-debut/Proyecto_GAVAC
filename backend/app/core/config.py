import json
from urllib.parse import urlsplit

from pydantic import Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import URL


PLACEHOLDER_SECRET_MARKERS = (
    "change-this", "change_this", "changeme", "change-me", "cambiar", "example",
    "ejemplo", "placeholder", "your-secret", "test-only", "secret-key",
)


class Settings(BaseSettings):
    database_url: str = ""
    postgres_user: str = ""
    postgres_password: SecretStr = SecretStr("")
    postgres_db: str = ""
    postgres_host: str = "postgres.railway.internal"
    postgres_port: int = Field(default=5432, ge=1, le=65535)
    jwt_secret_key: SecretStr = Field(min_length=32)
    jwt_expire_minutes: int = Field(default=60, gt=0)
    environment: str = "production"
    cors_origins: str = ""
    recaptcha_secret_key: SecretStr = SecretStr("")
    recaptcha_allowed_hostnames: str = (
        "proyectogestionganadera-production.up.railway.app,localhost,127.0.0.1,testserver"
    )
    smtp_host: str = ""
    smtp_port: int = Field(default=587, ge=1, le=65535)
    smtp_username: str = ""
    smtp_password: SecretStr = SecretStr("")
    smtp_from_email: str = ""

    model_config = SettingsConfigDict(
        env_file=(".env", "../.env"),
        extra="ignore",
    )

    @model_validator(mode="before")
    @classmethod
    def configure_database_url(cls, values: object) -> object:
        if not isinstance(values, dict):
            return values

        environment = str(values.get("environment") or "production").strip().lower()
        database_url = values.get("database_url")
        if isinstance(database_url, str):
            database_url = database_url.strip().strip("'\"")
        if database_url:
            values["database_url"] = database_url
            return values

        if environment != "production":
            values["database_url"] = "sqlite:///./app.db"
            return values

        username = values.get("postgres_user") or ""
        password = values.get("postgres_password") or ""
        database = values.get("postgres_db") or ""
        host = values.get("postgres_host") or "postgres.railway.internal"
        port = values.get("postgres_port") or 5432

        if isinstance(password, SecretStr):
            password = password.get_secret_value()

        if not all(str(item).strip() for item in (username, password, database, host)):
            raise ValueError(

            "DATABASE_URL is required when ENVIRONMENT=production. "
            "Está vacía y no se pudieron construir las credenciales con "
            "POSTGRES_USER, POSTGRES_PASSWORD y POSTGRES_DB"

            )

        values["database_url"] = URL.create(
            drivername="postgresql+psycopg",
            username=str(username),
            password=str(password),
            host=str(host),
            port=int(port),
            database=str(database),
        ).render_as_string(hide_password=False)
        return values

    @model_validator(mode="after")
    def reject_placeholder_jwt_secret(self) -> "Settings":
        if self.environment.strip().lower() == "production":
            secret = self.jwt_secret_key.get_secret_value().lower()
            if any(marker in secret for marker in PLACEHOLDER_SECRET_MARKERS):
                raise ValueError(
                    "JWT_SECRET_KEY parece un texto de ejemplo; genera una clave aleatoria "
                    "para producción (python -c \"import secrets; print(secrets.token_urlsafe(48))\")"
                )
        return self

    @field_validator("database_url", mode="before")
    @classmethod
    def validate_database_url(cls, value: object) -> str:
        if value is None:
            return ""
        if not isinstance(value, str):
            value = str(value)
        value = value.strip().strip("'\"")
        if value.startswith("postgres://"):
            return value.replace("postgres://", "postgresql+psycopg://", 1)
        if value.startswith("postgresql://"):
            return value.replace("postgresql://", "postgresql+psycopg://", 1)
        return value

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins_input(cls, value: object) -> str:
        if value is None:
            return ""
        if isinstance(value, list):
            return ",".join(str(item) for item in value)
        if isinstance(value, str):
            val = value.strip()
            if val.startswith("[") and val.endswith("]"):
                try:
                    parsed = json.loads(val)
                    if isinstance(parsed, list):
                        return ",".join(str(item) for item in parsed)
                except json.JSONDecodeError:
                    pass
            return val
        return str(value)

    @field_validator("cors_origins")
    @classmethod
    def validate_cors_origins(cls, value: str) -> str:
        origins = []
        for configured_origin in value.split(","):
            origin = configured_origin.strip()
            if not origin:
                continue
            parsed = urlsplit(origin)
            hostname = parsed.hostname
            if (
                    origin == "*"
                    or parsed.scheme not in {"http", "https"}
                    or not hostname
                    or parsed.username is not None
                    or parsed.password is not None
                    or parsed.path not in {"", "/"}
                    or parsed.query
                    or parsed.fragment
            ):
                raise ValueError(
                    "CORS_ORIGINS debe contener orígenes HTTP(S) exactos, sin rutas ni comodines"
                )
            try:
                parsed.port
            except ValueError as error:
                raise ValueError("CORS_ORIGINS contiene un puerto inválido") from error
            if parsed.netloc.endswith(":"):
                raise ValueError("CORS_ORIGINS contiene un puerto vacío")
            if parsed.scheme == "http" and hostname.lower() not in {
                "localhost", "127.0.0.1", "::1"
            }:
                raise ValueError("Los orígenes HTTP solo se permiten en loopback")
            origins.append(origin.rstrip("/"))
        return ",".join(dict.fromkeys(origins))

    @property
    def allowed_cors_origins(self) -> list[str]:
        return [origin for origin in self.cors_origins.split(",") if origin]

    @property
    def allowed_recaptcha_hostnames(self) -> set[str]:
        return {
            hostname.strip().rstrip(".").lower()
            for hostname in self.recaptcha_allowed_hostnames.split(",")
            if hostname.strip()
        }

    @property
    def smtp_is_configured(self) -> bool:
        return all(
            (
                self.smtp_host,
                self.smtp_username,
                self.smtp_password.get_secret_value(),
                self.smtp_from_email,
            )
        )


settings = Settings()
