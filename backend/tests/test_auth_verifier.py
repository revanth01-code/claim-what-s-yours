"""Tests for the Firebase ID-token verifier and its SDK-to-application error mapping.

The Firebase SDK token check and the app lookup are monkeypatched, so no test needs
credentials or network access. The endpoint-level cases use the real verifier
dependency (no override) and only replace the SDK call.
"""

from collections.abc import Callable, Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient
from firebase_admin import auth as firebase_auth
from google.auth import exceptions as google_auth_exceptions

from app.core.config import get_settings
from app.core.exceptions import (
    AccountDisabledError,
    AuthenticationError,
    AuthServiceUnavailableError,
)
from app.modules.auth import firebase as firebase_module
from app.modules.auth import verifier as verifier_module
from app.modules.auth.firebase import FirebaseConfigurationError, reset_firebase_app_cache
from app.modules.auth.verifier import FirebaseIdTokenVerifier, VerifiedIdentity

TOKEN = "header.payload.signature"
SENTINEL_APP = object()


@pytest.fixture(autouse=True)
def _reset_firebase_cache() -> Iterator[None]:
    """Clear the cached Firebase app before and after each test."""
    reset_firebase_app_cache()
    yield
    reset_firebase_app_cache()


@pytest.fixture
def sdk_verify(
    monkeypatch: pytest.MonkeyPatch,
) -> Callable[[Callable[..., Any]], None]:
    """Replace the app lookup with a sentinel and return an installer for verify_id_token."""
    monkeypatch.setattr(verifier_module, "get_firebase_app", lambda: SENTINEL_APP)

    def install(fake: Callable[..., Any]) -> None:
        monkeypatch.setattr(verifier_module.firebase_auth, "verify_id_token", fake)

    return install


def sdk_returning(
    install: Callable[[Callable[..., Any]], None],
    decoded: dict[str, Any] | None = None,
    error: BaseException | None = None,
) -> list[dict[str, Any]]:
    """Install a fake verify_id_token that returns decoded or raises error; record its calls."""
    calls: list[dict[str, Any]] = []

    def fake(id_token: str, app: object = None, check_revoked: bool = False) -> dict[str, Any]:
        calls.append({"id_token": id_token, "app": app, "check_revoked": check_revoked})
        if error is not None:
            raise error
        assert decoded is not None
        return decoded

    install(fake)
    return calls


def test_claims_map_to_verified_identity(
    sdk_verify: Callable[[Callable[..., Any]], None],
) -> None:
    calls = sdk_returning(
        sdk_verify,
        decoded={"uid": "u1", "email": "a@x.com", "email_verified": True, "name": "A"},
    )

    identity = FirebaseIdTokenVerifier().verify(TOKEN)

    assert identity == VerifiedIdentity(uid="u1", email="a@x.com", email_verified=True, name="A")
    assert calls == [{"id_token": TOKEN, "app": SENTINEL_APP, "check_revoked": True}]


@pytest.mark.parametrize(
    "extra_claims",
    [{}, {"email_verified": False}, {"email_verified": "true"}, {"email_verified": 1}],
)
def test_email_verified_is_true_only_for_boolean_true_claim(
    sdk_verify: Callable[[Callable[..., Any]], None],
    extra_claims: dict[str, Any],
) -> None:
    decoded = {"uid": "u1", "email": "a@gmail.com", **extra_claims}
    sdk_returning(sdk_verify, decoded=decoded)

    identity = FirebaseIdTokenVerifier().verify(TOKEN)

    assert identity.email_verified is False
    assert identity.name is None


def test_sub_claim_is_used_when_uid_claim_is_absent(
    sdk_verify: Callable[[Callable[..., Any]], None],
) -> None:
    sdk_returning(sdk_verify, decoded={"sub": "s1", "email": "a@x.com"})

    identity = FirebaseIdTokenVerifier().verify(TOKEN)

    assert identity.uid == "s1"


@pytest.mark.parametrize(
    "decoded",
    [
        {"uid": ""},
        {"uid": "", "sub": "s1"},
        {"uid": None},
        {"sub": ""},
        {},
    ],
)
def test_empty_or_missing_uid_is_rejected(
    sdk_verify: Callable[[Callable[..., Any]], None],
    decoded: dict[str, Any],
) -> None:
    sdk_returning(sdk_verify, decoded=decoded)

    with pytest.raises(AuthenticationError):
        FirebaseIdTokenVerifier().verify(TOKEN)


def test_empty_uid_returns_401_over_http(
    client: TestClient,
    sdk_verify: Callable[[Callable[..., Any]], None],
) -> None:
    sdk_returning(sdk_verify, decoded={"uid": ""})

    response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {TOKEN}"})

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_failed"
    assert response.headers["WWW-Authenticate"] == "Bearer"


@pytest.mark.parametrize(
    ("make_error", "expected_message"),
    [
        (
            lambda: firebase_auth.ExpiredIdTokenError("expired", None),
            "Authentication token has expired",
        ),
        (
            lambda: firebase_auth.RevokedIdTokenError("revoked"),
            "Authentication token has been revoked",
        ),
        (
            lambda: firebase_auth.InvalidIdTokenError("invalid", None),
            "Invalid authentication token",
        ),
    ],
)
def test_sdk_token_errors_map_to_401(
    sdk_verify: Callable[[Callable[..., Any]], None],
    make_error: Callable[[], BaseException],
    expected_message: str,
) -> None:
    # The SDK constructor signatures are assumed to be (message, cause). If they differ,
    # make_error() raises TypeError and this test fails loudly by design.
    sdk_returning(sdk_verify, error=make_error())

    with pytest.raises(AuthenticationError) as exc_info:
        FirebaseIdTokenVerifier().verify(TOKEN)

    assert str(exc_info.value) == expected_message


def test_sdk_user_disabled_maps_to_account_disabled(
    sdk_verify: Callable[[Callable[..., Any]], None],
) -> None:
    # Assumed constructor signature: (message, cause). See note in test above.
    sdk_returning(sdk_verify, error=firebase_auth.UserDisabledError("disabled", None))

    with pytest.raises(AccountDisabledError):
        FirebaseIdTokenVerifier().verify(TOKEN)


def test_unknown_sdk_failure_maps_to_503_without_leaking_message(
    client: TestClient,
    sdk_verify: Callable[[Callable[..., Any]], None],
) -> None:
    sdk_returning(sdk_verify, error=RuntimeError("boom"))

    with pytest.raises(AuthServiceUnavailableError):
        FirebaseIdTokenVerifier().verify(TOKEN)

    response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {TOKEN}"})

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "auth_service_unavailable"
    assert "boom" not in response.text


@pytest.mark.parametrize(
    ("make_error", "leaked_text"),
    [
        (
            lambda: google_auth_exceptions.TransportError("connection reset"),
            "connection reset",
        ),
        (
            lambda: firebase_auth.CertificateFetchError("fetch failed", cause=None),
            "fetch failed",
        ),
        (
            lambda: google_auth_exceptions.RefreshError("refresh failed"),
            "refresh failed",
        ),
    ],
)
def test_sdk_transport_failures_map_to_503_not_401(
    sdk_verify: Callable[[Callable[..., Any]], None],
    make_error: Callable[[], BaseException],
    leaked_text: str,
) -> None:
    # Constructor calls run inside the test body: a signature mismatch in the SDK
    # raises TypeError here and fails the test loudly instead of being hidden.
    sdk_returning(sdk_verify, error=make_error())

    with pytest.raises(AuthServiceUnavailableError) as exc_info:
        FirebaseIdTokenVerifier().verify(TOKEN)

    assert leaked_text not in str(exc_info.value)


def test_sdk_transport_failure_returns_503_over_http(
    client: TestClient,
    sdk_verify: Callable[[Callable[..., Any]], None],
) -> None:
    sdk_returning(
        sdk_verify,
        error=google_auth_exceptions.TransportError("connection reset"),
    )

    response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {TOKEN}"})

    assert response.status_code == 503
    assert response.status_code != 401
    assert response.json()["error"]["code"] == "auth_service_unavailable"
    assert "connection reset" not in response.text


def test_firebase_configuration_error_maps_to_503_and_skips_sdk(
    monkeypatch: pytest.MonkeyPatch,
    sdk_verify: Callable[[Callable[..., Any]], None],
) -> None:
    def raise_config_error() -> object:
        raise FirebaseConfigurationError()

    monkeypatch.setattr(verifier_module, "get_firebase_app", raise_config_error)
    calls = sdk_returning(sdk_verify, decoded={"uid": "u1"})

    with pytest.raises(AuthServiceUnavailableError):
        FirebaseIdTokenVerifier().verify(TOKEN)

    assert calls == []


def test_firebase_configuration_error_does_not_leak_credentials_path(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path,
) -> None:
    # Certificate() on a missing file fails before any network call.
    missing = tmp_path / "does-not-exist" / "service-account.json"
    monkeypatch.setenv("CWY_FIREBASE_CREDENTIALS_PATH", str(missing))
    get_settings.cache_clear()
    reset_firebase_app_cache()

    with pytest.raises(FirebaseConfigurationError) as exc_info:
        firebase_module.get_firebase_app()

    message = str(exc_info.value)
    assert str(missing) not in message
    assert "service-account.json" not in message
