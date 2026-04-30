from fastapi import FastAPI
from engine.src.api import routes

app = FastAPI(title="SikuLight Engine API")

app.include_router(routes.router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
