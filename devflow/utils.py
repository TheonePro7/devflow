"""devflow 工具函数 — CLI 命令间共享的公共逻辑。"""

from __future__ import annotations

from pathlib import Path


def detect_test_commands(project_path: Path) -> list[str]:
    """自动检测项目使用的测试框架，返回可能的测试命令列表。"""
    checks = [
        (project_path / "package.json", ["npm test", "npm run test", "npx jest", "npx vitest run"]),
        (project_path / "pytest.ini", ["python -m pytest"]),
        (project_path / "pyproject.toml", ["python -m pytest", "pytest"]),
        (project_path / "setup.cfg", ["python -m pytest"]),
        (project_path / "go.mod", ["go test ./..."]),
        (project_path / "Cargo.toml", ["cargo test"]),
        (project_path / "Makefile", ["make test"]),
    ]
    for config_file, cmds in checks:
        if config_file.exists():
            return cmds
    return []
