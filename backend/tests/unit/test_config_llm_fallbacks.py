"""The primary model is Gemini and falls back through the recommended Gemini order."""
from src.config import DEFAULT_GEMINI_FALLBACK_MODELS, DEFAULT_LLM, Config


def test_gemini_is_the_default_model(monkeypatch):
    monkeypatch.delenv("LLM", raising=False)
    monkeypatch.setenv("GOOGLE_API_KEY", "test-key")

    config = Config()

    assert DEFAULT_LLM == "google-gla:gemini-3.8-flash"
    assert config.llm == DEFAULT_LLM


def test_gemini_defaults_to_the_recommended_fallback_order(monkeypatch):
    monkeypatch.delenv("LLM_FALLBACK_MODELS", raising=False)
    monkeypatch.setenv("LLM", DEFAULT_LLM)

    config = Config()

    assert config.resolve_llm_fallbacks() == [
        "google-gla:gemini-3.5-flash-lite",
        "google-gla:gemini-2.5-flash",
        "google-gla:gemini-2.5-flash-lite",
    ]
    assert config.resolve_llm_fallbacks() == list(DEFAULT_GEMINI_FALLBACK_MODELS)


def test_explicit_fallback_chain_drops_the_primary_and_duplicates(monkeypatch):
    monkeypatch.setenv("LLM", DEFAULT_LLM)
    monkeypatch.setenv(
        "LLM_FALLBACK_MODELS",
        "google-gla:gemini-3.8-flash, google-gla:gemini-3.5-flash-lite,google-gla:gemini-3.5-flash-lite",
    )

    config = Config()

    assert config.resolve_llm_fallbacks() == ["google-gla:gemini-3.5-flash-lite"]


def test_non_google_model_has_no_configured_fallback(monkeypatch):
    monkeypatch.delenv("LLM_FALLBACK_MODELS", raising=False)
    monkeypatch.setenv("LLM", "anthropic:claude-4-sonnet")

    config = Config()

    assert config.resolve_llm_fallbacks() == []
