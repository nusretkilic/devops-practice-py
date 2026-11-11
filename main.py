from fastapi import FastAPI
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

app = FastAPI(title="DevOps Practice", version="1.0.0")

http_requests_total = Counter(
    "http_requests_total",
    "Total number of HTTP requests.",
    ["method", "path", "status"],
)


class MetricsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        http_requests_total.labels(
            method=request.method,
            path=request.url.path,
            status=response.status_code,
        ).inc()
        return response


app.add_middleware(MetricsMiddleware)


@app.get("/")
def root():
    return {"message": "DevOps Practice", "version": "1.0.0"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/metrics", include_in_schema=False)
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
