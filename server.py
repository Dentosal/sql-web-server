import argparse

import socket
import psycopg2

def main(host: str, port: int) -> None:
    psql = psycopg2.connect("user='postgres' dbname='sql-web-server'")
    curs = psql.cursor()

    with open("sql/init.sql") as f:
        curs.execute(f.read())

    sock = socket.socket()

    try:
        sock.bind((host, port))
    except socket.error as err:
        print("Could not bind: " + str(err))
        exit()

    sock.listen(10)

    while True:
        print("PENDING ACCEPT")
        conn, addr = sock.accept()
        print("ACCEPTED")

        text = conn.recv(1024)
        print(text)

        curs.execute("INSERT INTO input (text, time) VALUES (%s, 'now') RETURNING id", (text.decode("utf-8"),))
        input_id = curs.fetchone()

        curs.execute("SELECT process(text) AS text FROM input WHERE id = %s", (input_id,))
        rows = curs.fetchone()

        assert len(rows) == 1, "No result"
        result = rows[0].encode("utf-8")
        print(result)
        assert result.endswith(b"\r\n")
        conn.send(result)

        conn.close()
        psql.commit()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SQL-based web server")
    parser.add_argument("--host", help="host name", default="127.0.0.1")
    parser.add_argument('--port', help="port number", type=int, default=8080)

    args = parser.parse_args()

    main(args.host, args.port)
