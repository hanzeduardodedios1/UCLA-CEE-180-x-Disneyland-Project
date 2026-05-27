from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health_returns_200():
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "hotels" in data


def test_hotel_names_returns_list():
    response = client.get("/api/hotels/names")
    assert response.status_code == 200
    names = response.json()
    assert isinstance(names, list)
    assert len(names) > 0
    assert all(isinstance(name, str) for name in names)


def test_search_rate_limit_429_after_30_requests():
    params = {"q": "Disneyland Hotel", "exact": True}
    for _ in range(30):
        response = client.get("/api/hotels/search", params=params)
        assert response.status_code == 200

    response = client.get("/api/hotels/search", params=params)
    assert response.status_code == 429
