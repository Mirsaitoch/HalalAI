"""Точка входа __main__ в api/main.py (uvicorn.run подменён)."""

from pathlib import Path
from unittest.mock import patch

import runpy


def test_main_py_invokes_uvicorn_when_run_as_script():
    service_root = Path(__file__).resolve().parents[2]
    main_py = service_root / "src" / "halal_rag" / "api" / "main.py"
    assert main_py.is_file(), f"expected {main_py}"

    with patch("uvicorn.run") as uvicorn_run:
        runpy.run_path(str(main_py), run_name="__main__")

    uvicorn_run.assert_called_once()
    _args, kwargs = uvicorn_run.call_args
    assert kwargs.get("host") == "localhost"
    assert kwargs.get("port") == 8001
