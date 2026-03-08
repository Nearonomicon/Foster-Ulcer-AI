import json
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.encoders import jsonable_encoder
from fastapi.middleware.cors import CORSMiddleware

from routes.patients import router as patients_router
from routes.cases import router as cases_router
from routes.analysis import router as analysis_router


app = FastAPI(title="Wound Care AI Analysis API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=False,
)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    try:
        body = await request.body()
        content_type = request.headers.get("content-type", "")
        if "application/json" in content_type:
            try:
                payload = json.loads(body.decode("utf-8")) if body else None
            except Exception:
                payload = body.decode("utf-8", errors="replace")
        else:
            payload = f"{len(body)} bytes"
        print(f"[REQUEST] {request.method} {request.url.path} content_type={content_type} payload={payload}")
        request._body = body
    except Exception as e:
        print(f"[REQUEST] {request.method} {request.url.path} error reading body: {e}")

    try:
        response = await call_next(request)
        print(f"[RESPONSE] {request.method} {request.url.path} status={response.status_code}")
        return response
    except Exception as e:
        import traceback
        print(f"[ERROR] {request.method} {request.url.path} {e}")
        print(traceback.format_exc())
        raise


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    import traceback
    print(f"[ERROR] {request.method} {request.url.path} HTTPException status={exc.status_code} detail={exc.detail}")
    print("".join(traceback.format_exception(type(exc), exc, exc.__traceback__)))
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    import traceback
    print(f"[ERROR] {request.method} {request.url.path} RequestValidationError")
    print("".join(traceback.format_exception(type(exc), exc, exc.__traceback__)))
    errors = exc.errors()
    for err in errors:
        if isinstance(err.get("ctx"), dict):
            err["ctx"] = {k: str(v) for k, v in err["ctx"].items()}
    return JSONResponse(status_code=422, content=jsonable_encoder({"detail": errors}))


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    import traceback
    print(f"[ERROR] {request.method} {request.url.path} {exc}")
    print("".join(traceback.format_exception(type(exc), exc, exc.__traceback__)))
    return JSONResponse(status_code=500, content={"detail": "Internal Server Error"})


@app.post("/load-dashboard")
async def load_dashboard():
    return {"message": "CORS is working!"}


app.include_router(patients_router)
app.include_router(cases_router)
app.include_router(analysis_router)
