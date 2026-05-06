"""devflow 集成测试 — 在临时目录测试完整流程。

标记为 @pytest.mark.integration，默认不执行：
  pytest tests/ -v                          # 只跑单元测试
  pytest tests/ -v -m integration           # 只跑集成测试
  pytest tests/ -v -m ""                    # 跑所有
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path

import pytest




def _run_devflow(*args: str) -> str:
    """用子进程运行 devflow 命令并返回 stdout。"""
    import subprocess
    result = subprocess.run(
        [sys.executable, "-m", "devflow.cli.main", *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=30,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"devflow {' '.join(args)} 退出码 {result.returncode}\n"
            f"stderr: {result.stderr[:500]}"
        )
    return result.stdout


@pytest.mark.integration
class TestIntegration:
    def test_init_creates_devflow_dir(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            assert (path / ".devflow").exists()

    def test_init_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            _run_devflow("init", "--path", str(path))  # 第二次应不报错
            assert (path / ".devflow").exists()

    def test_state_shows_phase0(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            # state 应正常显示
            _run_devflow("state", "--path", str(path))

    def test_transition_phase1_dry_run(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            _run_devflow("transition", "phase-1/start", "--dry-run", "--path", str(path))

    def test_sync_runs_without_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            _run_devflow("sync", "--path", str(path))

    def test_log(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            # 先做一次 transition 产生日志
            _run_devflow("transition", "phase-1/start", "--dry-run", "--path", str(path))
            _run_devflow("log", "--path", str(path))

    def test_log_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            _run_devflow("transition", "phase-1/start", "--dry-run", "--path", str(path))
            # --json 应输出合法 JSON
            _run_devflow("log", "--json", "--path", str(path))

    def test_task_list(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            _run_devflow("task", "list", "--path", str(path))

    def test_doctor(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            _run_devflow("doctor", "--path", str(path))

    def test_guide(self):
        _run_devflow("guide")

    def test_guide_path(self):
        # guide 命令不需要 --path，只是在临时目录测试能否运行
        _run_devflow("guide")

    def test_state_log_file_created(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _run_devflow("init", "--path", str(path))
            _run_devflow("transition", "phase-1/start", "--dry-run", "--path", str(path))
            log_file = path / ".devflow" / "state.log"
            assert log_file.exists()
            content = log_file.read_text(encoding="utf-8")
            assert "phase-0" in content
