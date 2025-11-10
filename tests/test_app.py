import pytest
from app import create_app

@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as c:
        yield c

def test_index(client):
    r = client.get("/")
    assert r.status_code == 200
    assert b"ACEest Fitness" in r.data

def test_add_and_get_workout_json(client):
    payload = {"category": "Workout", "exercise": "Push-ups", "duration": 15}
    r = client.post("/api/workouts", json=payload)
    assert r.status_code == 201
    data = r.get_json()
    assert data["status"] == "ok"
    r2 = client.get("/api/workouts")
    store = r2.get_json()
    assert "Workout" in store
    assert any(item["exercise"] == "Push-ups" for item in store["Workout"])

def test_add_bad_duration(client):
    payload = {"category": "Workout", "exercise": "Situps", "duration": "abc"}
    r = client.post("/api/workouts", json=payload)
    assert r.status_code == 400

def test_add_missing_fields(client):
    payload = {"category": "Warm-up", "exercise": ""}
    r = client.post("/api/workouts", json=payload)
    assert r.status_code == 400
