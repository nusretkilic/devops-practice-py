from fastapi import FastAPI

app = FastAPI(title="DevOps Practice", version="1.0.0")


@app.get("/")
def root():
    return {"message": "DevOps Practice", "version": "1.0.0"}


@app.get("/health")
def health():
    return {"status": "ok"}