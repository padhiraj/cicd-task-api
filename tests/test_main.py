from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_root():
    response = client.get("/")

    assert response.status_code == 200
    assert response.json()["message"] == "CI/CD Task API is running"


def test_health():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_tasks():
    response = client.get("/tasks")

    assert response.status_code == 200
    assert len(response.json()["tasks"]) == 3