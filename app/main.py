from fastapi import FastAPI

app = FastAPI(title="CI/CD Task API")


@app.get("/")
def root():
    return {
        "message": "CI/CD Task API is running"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }


@app.get("/tasks")
def get_tasks():
    return {
        "tasks": [
            {"id": 1, "title": "Learn CI/CD"},
            {"id": 2, "title": "Build Docker Image"},
            {"id": 3, "title": "Deploy Application"},
        ]
    }