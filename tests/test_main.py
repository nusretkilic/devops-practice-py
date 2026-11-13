import asyncio
from unittest.mock import AsyncMock

from fastapi.testclient import TestClient
from starlette.requests import Request
from starlette.responses import Response

from main import MetricsMiddleware, app

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "DevOps Practice", "version": "1.0.0"}


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_metrics():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain")
    assert b"http_requests_total" in response.content


def test_unknown_route_returns_not_found():
    response = client.get("/does-not-exist")

    assert response.status_code == 404


def test_metrics_middleware_calls_next_with_mock():
    scope = {
        "type": "http",
        "method": "GET",
        "path": "/health",
        "raw_path": b"/health",
        "query_string": b"",
        "headers": [],
        "scheme": "http",
        "server": ("testserver", 80),
        "client": ("testclient", 50000),
        "root_path": "",
        "http_version": "1.1",
    }
    request = Request(scope)
    response = Response(status_code=204)
    call_next = AsyncMock(return_value=response)

    result = asyncio.run(MetricsMiddleware(app).dispatch(request, call_next))

    assert result is response
    call_next.assert_awaited_once_with(request)
