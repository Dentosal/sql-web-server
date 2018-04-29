import requests as rq

def test_get(server):
    r = rq.get("http://localhost:8080/")
    r.raise_for_status()
    assert r.headers["server"] == "SQL-Web/0.1.0"

def test_post(server):
    r = rq.post("http://localhost:8080/")
    assert r.status_code == 405
