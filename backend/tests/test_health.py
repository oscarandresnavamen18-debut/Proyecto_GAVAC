def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "gestion-ganadera-api"}


def test_unconfigured_origins_are_not_allowed_by_cors(client):
    response = client.options(
        "/health",
        headers={
            "Origin": "https://unconfigured.example.invalid",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert "access-control-allow-origin" not in response.headers
