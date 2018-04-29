# sql-web-server

Web server with all logic written in SQL.

# Dependencies

Python >= 3.5, `python3 -m pip install -r requirements.txt`

PostgreSQL installed, and database `sql-web-server` created.
Currently using local `trust` authentication in `pg_hba.conf`.

# Running

`python3 server.py`

# Running tests

* Test: `python3 -m pytest`
* Typecheck: `python3 -m mypy --ignore-missing-imports --strict-optional .`