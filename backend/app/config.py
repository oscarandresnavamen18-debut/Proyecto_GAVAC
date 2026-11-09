import json
from urllib.parse import urlsplit

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = Field(min_length=1)
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
        env_file=(".env", "../.env"), extra="ignore")

    @field_validator("database_url", mode="before")
    @classmethod
    def validate_database_url(cls, value: object) -> str:
        if not isinstance(value, str):
            value = str(value)
        value = value.strip("'\" \t\r\n")
        if value.startswith("postgres://"):
            return value.replace("postgres://", "postgresql+psycopg://", 1)
        if value.startswith("postgresql://") and not value.startswith("postgresql+psycopg://"):
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
                    "CORS_ORIGINS debe contener orígenes HTTP(S) exactos, sin rutas ni comodines")

            try:
                parsed.port
            except ValueError as error:
                raise ValueError(
                    "CORS_ORIGINS contiene un puerto inválido") from error
            if parsed.netloc.endswith(":"):
                raise ValueError("CORS_ORIGINS contiene un puerto vacío")

            if parsed.scheme == "http" and hostname.lower() not in {"localhost", "127.0.0.1", "::1"}:
                raise ValueError(
                    "Los orígenes HTTP solo se permiten en loopback")

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
