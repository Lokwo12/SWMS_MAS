from __future__ import annotations

import os
import re
import subprocess
import uuid
from datetime import datetime, UTC
from pathlib import Path
from threading import Lock

from app.models.schemas import OperationResponse, SystemStatus


ROOT_DIR = Path("/home/studente/Simple")
SESSION_NAME = "DALI_session"

ALLOWED_ACTIONS = {
    "start": ["./startmas.sh"],
    "stop": ["./stopmas.sh", SESSION_NAME],
    "restart": ["./restartmas.sh", SESSION_NAME],
    "healthcheck": ["./healthcheck.sh", SESSION_NAME],
}

_state_lock = Lock()
_state = "idle"
MAX_MESSAGE_CHARS = 1200
ANSI_ESCAPE_RE = re.compile(r"\x1B\[[0-?]*[ -/]*[@-~]")


def _set_state(value: str) -> None:
    global _state
    with _state_lock:
        _state = value


def _normalize_message(output: str | None, fallback: str) -> str:
    text = ANSI_ESCAPE_RE.sub("", (output or "")).replace("\r\n", "\n").replace("\r", "\n").strip()
    if not text:
        return fallback

    lines = [line.rstrip() for line in text.split("\n") if line.strip()]
    if not lines:
        return fallback

    cleaned = "\n".join(lines)
    if len(cleaned) <= MAX_MESSAGE_CHARS:
        return cleaned

    head_budget = MAX_MESSAGE_CHARS // 2 - 10
    tail_budget = MAX_MESSAGE_CHARS - head_budget - 10

    head: list[str] = []
    used = 0
    for line in lines:
        add = len(line) + (1 if head else 0)
        if used + add > head_budget:
            break
        head.append(line)
        used += add

    tail: list[str] = []
    used = 0
    for line in reversed(lines):
        add = len(line) + (1 if tail else 0)
        if used + add > tail_budget:
            break
        tail.append(line)
        used += add
    tail.reverse()

    merged = "\n".join(head + ["...", *tail]).strip()
    if merged:
        return merged

    return cleaned[:MAX_MESSAGE_CHARS]


def _clean_env() -> dict[str, str]:
    run_env = os.environ.copy()
    run_env.pop("TMUX", None)
    return run_env


def get_status() -> SystemStatus:
    run_env = _clean_env()
    session_running = subprocess.run(
        ["tmux", "has-session", "-t", SESSION_NAME],
        cwd=ROOT_DIR,
        capture_output=True,
        text=True,
        check=False,
        env=run_env,
    ).returncode == 0

    sicstus_running = subprocess.run(
        ["pgrep", "-x", "sicstus"],
        cwd=ROOT_DIR,
        capture_output=True,
        text=True,
        check=False,
        env=run_env,
    ).returncode == 0

    effective_state = "running" if (session_running and sicstus_running) else (_state if _state in {"idle", "running", "failed"} else "idle")

    return SystemStatus(
        service="mas-control-api",
        state=effective_state,
        session=SESSION_NAME,
        timestamp=datetime.now(UTC),
    )


def run_action(action: str) -> OperationResponse:
    if action not in ALLOWED_ACTIONS:
        raise ValueError(f"Unsupported action: {action}")

    request_id = f"op_{datetime.now(UTC).strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:6]}"
    started_at = datetime.now(UTC)
    run_env = _clean_env()
    if action in {"start", "restart"}:
        run_env["NO_ATTACH"] = "1"

    _set_state("running")

    try:
        completed = subprocess.run(
            ALLOWED_ACTIONS[action],
            cwd=ROOT_DIR,
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
            env=run_env,
        )
        finished_at = datetime.now(UTC)

        if completed.returncode == 0:
            _set_state("idle")
            return OperationResponse(
                requestId=request_id,
                action=action,  # type: ignore[arg-type]
                status="completed",
                startedAt=started_at,
                finishedAt=finished_at,
                exitCode=completed.returncode,
                message=_normalize_message(completed.stdout, "ok"),
            )

        _set_state("failed")
        return OperationResponse(
            requestId=request_id,
            action=action,  # type: ignore[arg-type]
            status="failed",
            startedAt=started_at,
            finishedAt=finished_at,
            exitCode=completed.returncode,
            message=_normalize_message((completed.stderr or completed.stdout), "failed"),
        )

    except subprocess.TimeoutExpired:
        _set_state("failed")
        return OperationResponse(
            requestId=request_id,
            action=action,  # type: ignore[arg-type]
            status="failed",
            startedAt=started_at,
            finishedAt=datetime.now(UTC),
            exitCode=124,
            message="operation timed out",
        )
