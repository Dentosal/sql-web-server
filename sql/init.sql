-- Tables

DROP TABLE IF EXISTS input;
CREATE TABLE input (
    id SERIAL,
    text TEXT NOT NULL,
    time TIMESTAMP NOT NULL
);

DROP TABLE IF EXISTS pages;
CREATE TABLE pages (
    id SERIAL,
    path TEXT NOT NULL,
    text TEXT NOT NULL
);

DROP TABLE IF EXISTS error_pages;
CREATE TABLE error_pages (
    id SERIAL,
    status INTEGER NOT NULL,
    text TEXT NOT NULL
);

-- Error Pages

INSERT INTO error_pages (status, text) VALUES
    (404, 'Page not found'),
    (405, 'Method not allowed')
;

-- Pages

INSERT INTO pages (path, text) VALUES
    ('/', '<!doctype html><html><head><meta charset="utf-8"><title>Example page</title></head><h1>Example page</h1><body></body></html>')
;

-- Functions

CREATE OR REPLACE FUNCTION parse_method(request TEXT) RETURNS TEXT LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT split_part(split_part($1, chr(13) || chr(10), 1), ' ', 1);
$$;

CREATE OR REPLACE FUNCTION parse_path(request TEXT) RETURNS TEXT LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT split_part(split_part($1, chr(13) || chr(10), 1), ' ', 2);
$$;

CREATE OR REPLACE FUNCTION parse_protocol(request TEXT) RETURNS TEXT LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT split_part(split_part($1, chr(13) || chr(10), 1), ' ', 3);
$$;


CREATE OR REPLACE FUNCTION line(TEXT) RETURNS TEXT LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT $1 || chr(13) || chr(10) AS result;
$$;

CREATE OR REPLACE FUNCTION header(key TEXT, value TEXT) RETURNS TEXT LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT line($1 || TEXT ': ' || $2) AS result;
$$;

CREATE OR REPLACE FUNCTION default_headers(request TEXT) RETURNS TEXT LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT header(TEXT 'server', TEXT 'SQL-Web/0.1.0');
$$;

CREATE OR REPLACE FUNCTION process(request TEXT) RETURNS TEXT LANGUAGE SQL VOLATILE STRICT AS $$
    SELECT CASE
        WHEN parse_method(request) = 'GET' THEN (
            SELECT
                COALESCE (
                    line(TEXT 'HTTP/1.1 200 OK') || default_headers($1) || line(TEXT '') || line(
                        (SELECT text FROM pages WHERE path = parse_path($1))
                    ),
                    line(TEXT 'HTTP/1.1 404 ' || (SELECT text FROM error_pages WHERE status = 404)) || default_headers($1) || line(TEXT '') ||
                        line(xmlserialize(CONTENT xmlforest((SELECT text FROM error_pages WHERE status = 404) AS h1) AS TEXT))
                )
        )
        ELSE (
            line(TEXT 'HTTP/1.1 405 ' || (SELECT text FROM error_pages WHERE status = 405)) || default_headers($1) || line(TEXT '') ||
                line(xmlserialize(CONTENT xmlforest((SELECT text FROM error_pages WHERE status = 405) AS h1) AS TEXT))
        )
    END AS result;
$$;