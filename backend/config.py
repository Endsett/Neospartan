"""Configuration management for NeoSpartan Backend."""

from functools import lru_cache
from typing import List, Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )
    
    # Application
    app_name: str = "NeoSpartan AI"
    app_version: str = "2.0.0"
    debug: bool = False
    environment: str = "development"
    
    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    workers: int = 1
    
    # Security - Must be set via environment variable
    secret_key: str = ""  # Set via SECRET_KEY env var
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days
    
    # CORS
    cors_origins: List[str] = ["http://localhost:3000", "https://neospartan.app"]
    allowed_hosts: List[str] = ["api.neospartan.ai", "localhost"]
    
    # Rate Limiting
    rate_limit: int = 100  # requests per minute
    rate_limit_window: int = 60  # seconds
    
    # Supabase
    supabase_url: str = ""
    supabase_key: str = ""  # service_role key for backend
    supabase_jwt_secret: str = ""
    
    # AI - Gemini
    gemini_api_key: str = ""
    gemini_model: str = "gemini-1.5-flash"  # or gemini-1.5-pro
    gemini_temperature: float = 0.7
    gemini_max_tokens: int = 2048
    
    # AI - OpenAI (fallback)
    openai_api_key: Optional[str] = None
    openai_model: str = "gpt-4-turbo-preview"
    
    # Redis (for caching & background tasks)
    redis_url: str = "redis://localhost:6379/0"
    
    # Background Tasks
    arq_worker_enabled: bool = True
    arq_max_jobs: int = 100
    arq_job_timeout: int = 300  # 5 minutes
    
    # Logging
    log_level: str = "INFO"
    json_logs: bool = True
    
    # Monitoring
    sentry_dsn: Optional[str] = None
    enable_metrics: bool = True
    
    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment.lower() == "production"
    
    @property
    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.environment.lower() == "development"
    
    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS origins from comma-separated string or list."""
        if isinstance(self.cors_origins, str):
            return [origin.strip() for origin in self.cors_origins.split(",")]
        return self.cors_origins
    
    @property
    def allowed_hosts_list(self) -> List[str]:
        """Parse allowed hosts from comma-separated string or list."""
        if isinstance(self.allowed_hosts, str):
            return [host.strip() for host in self.allowed_hosts.split(",")]
        return self.allowed_hosts


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


# Global settings instance
settings = get_settings()
