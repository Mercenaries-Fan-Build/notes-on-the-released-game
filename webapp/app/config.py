from __future__ import annotations

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://mercs2:mercs2@localhost:5432/mercs2"
    database_url_sync: str = "postgresql+psycopg2://mercs2:mercs2@localhost:5432/mercs2"
    output_root: str = "./output"
    review_root: str = "./output/extracted/review"
    cors_origins: list[str] = ["http://localhost:5173", "http://localhost:3000"]
    debug: bool = False
    page_size_default: int = 50
    page_size_max: int = 500

    model_config = {"env_prefix": "MERCS2_", "env_file": ".env"}


settings = Settings()
