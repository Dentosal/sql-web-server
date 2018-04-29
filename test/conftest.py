from pathlib import Path
import subprocess as sp

import pytest

@pytest.fixture
def server(request):
    proc = sp.Popen(["python3", str(Path(__file__).parent.parent / "server.py")])

    def fin():
        proc.kill()

    request.addfinalizer(fin)
