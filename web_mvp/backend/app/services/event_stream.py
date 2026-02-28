from __future__ import annotations

import asyncio
import json
import os
import re
import subprocess
import uuid
from datetime import datetime, UTC
from typing import Any

from fastapi import WebSocket

SESSION_CANDIDATES = ["DALI_session", "MAS"]
POLL_INTERVAL_SECONDS = 1.5
MAX_HISTORY_LINES = 120

DATA_PATTERNS = [
    re.compile(r"data=([^\n]+)$"),
    re.compile(r"->\s*([^\n]+)$"),
]

ACTION_LINE_PATTERN = re.compile(r"^(Control center\s*\||Truck\s+\w+\s*\||Bin\s+\w+\s*\|)")
NOISE_LINE_PATTERN = re.compile(r"^(SICStus\b|Licensed to\b|conf/communication|\|\s*\?-|Launching agent instance:)", re.IGNORECASE)

BIN_LEVEL_LINE_PATTERN = re.compile(r"Bin\s+(\w+)\s*\|\s*level:\s*([0-9]+)\s*%+", re.IGNORECASE)
BIN_ALERT_FULL_LINE_PATTERN = re.compile(r"Bin\s+(\w+)\s*\|\s*alert:\s*full", re.IGNORECASE)
BIN_RESET_LINE_PATTERN = re.compile(r"Bin\s+(\w+)\s*\|\s*reset:\s*", re.IGNORECASE)

EVENT_TYPE_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("bin_level", re.compile(r"status\(([^,]+),\s*([0-9]+)\)")),
    ("full_received", re.compile(r"full_received\(([^)]+)\)")),
    ("requesting", re.compile(r"requesting\(([^,]+),\s*([^,]+),\s*([^)]+)\)")),
    ("assigned", re.compile(r"assigned\(([^,]+),\s*([^)]+)\)")),
    ("refused", re.compile(r"refused\(([^,]+),\s*([^)]+)\)")),
    ("completed", re.compile(r"completed\(([^,]+),\s*([^)]+)\)")),
    ("reset", re.compile(r"reset\(([^)]+)\)")),
    ("working", re.compile(r"working\(([^,]+),\s*([^)]+)\)")),
    ("ready", re.compile(r"ready\(([^)]+)\)")),
]


class EventStreamService:
    def __init__(self) -> None:
        self._clients: set[WebSocket] = set()
        self._clients_lock = asyncio.Lock()
        self._pane_snapshots: dict[str, list[str]] = {}
        self._running = False

    def _run_tmux(self, args: list[str]) -> subprocess.CompletedProcess[str]:
        run_env = os.environ.copy()
        run_env.pop("TMUX", None)
        return subprocess.run(
            ["tmux", *args],
            capture_output=True,
            text=True,
            check=False,
            env=run_env,
        )

    async def register(self, ws: WebSocket) -> None:
        await ws.accept()
        async with self._clients_lock:
            self._clients.add(ws)

    async def unregister(self, ws: WebSocket) -> None:
        async with self._clients_lock:
            if ws in self._clients:
                self._clients.remove(ws)

    async def broadcast(self, payload: dict[str, Any]) -> None:
        text = json.dumps(payload)
        dead: list[WebSocket] = []
        async with self._clients_lock:
            for client in self._clients:
                try:
                    await client.send_text(text)
                except Exception:
                    dead.append(client)
            for client in dead:
                self._clients.discard(client)

    async def run_forever(self) -> None:
        if self._running:
            return
        self._running = True
        while True:
            try:
                events = self._collect_events_from_tmux()
                for event in events:
                    await self.broadcast(event)
            except Exception as exc:
                await self.broadcast(
                    {
                        "id": f"evt_{uuid.uuid4().hex[:10]}",
                        "ts": datetime.now(UTC).isoformat(),
                        "type": "stream_error",
                        "source": "event-parser",
                        "severity": "warn",
                        "data": {"message": str(exc)},
                    }
                )
            await asyncio.sleep(POLL_INTERVAL_SECONDS)

    def _collect_events_from_tmux(self) -> list[dict[str, Any]]:
        session = self._detect_session()
        if not session:
            return []

        panes = self._list_panes(session)
        if not panes:
            return []

        events: list[dict[str, Any]] = []

        active_pane_ids = {pane_id for pane_id, _ in panes}
        stale_panes = [pane_id for pane_id in self._pane_snapshots if pane_id not in active_pane_ids]
        for pane_id in stale_panes:
            self._pane_snapshots.pop(pane_id, None)

        for pane_id, pane_title in panes:
            output = self._run_tmux(["capture-pane", "-J", "-pt", pane_id, "-S", f"-{MAX_HISTORY_LINES}"])
            if output.returncode != 0:
                continue

            current_lines = [line.rstrip() for line in output.stdout.splitlines() if line.strip()]
            previous_lines = self._pane_snapshots.get(pane_id, [])
            new_lines = self._new_lines_since_snapshot(previous_lines, current_lines)
            self._pane_snapshots[pane_id] = current_lines[-MAX_HISTORY_LINES:]

            for line in new_lines:
                event = self._parse_line(line, pane_title)
                if event is not None:
                    events.append(event)

        return events

    def _detect_session(self) -> str | None:
        for session in SESSION_CANDIDATES:
            check = self._run_tmux(["has-session", "-t", session])
            if check.returncode == 0:
                return session
        return None

    def _list_panes(self, session: str) -> list[tuple[str, str]]:
        result = self._run_tmux(["list-panes", "-t", session, "-F", "#{pane_id} #{pane_title}"])
        if result.returncode != 0:
            return []

        panes: list[tuple[str, str]] = []
        for line in result.stdout.splitlines():
            parts = line.strip().split(" ", 1)
            if len(parts) != 2:
                continue
            pane_id, pane_title = parts
            panes.append((pane_id, pane_title or "unknown"))
        return panes

    def _new_lines_since_snapshot(self, previous: list[str], current: list[str]) -> list[str]:
        if not current:
            return []
        if not previous:
            return current

        max_overlap = min(len(previous), len(current))
        overlap = 0
        for k in range(max_overlap, 0, -1):
            if previous[-k:] == current[:k]:
                overlap = k
                break
        return current[overlap:]

    def _extract_data_fragment(self, line: str) -> str | None:
        for pattern in DATA_PATTERNS:
            m = pattern.search(line)
            if m:
                return m.group(1).strip()
        return None

    def _parse_line(self, line: str, pane_title: str) -> dict[str, Any] | None:
        normalized_line = re.sub(r"\s+", " ", line).strip()
        fragment = self._extract_data_fragment(line)

        if fragment is None:
            if NOISE_LINE_PATTERN.search(line):
                return None
            if not ACTION_LINE_PATTERN.search(line):
                return None

        event_type = "tmux_line"
        data: dict[str, Any] = {
            "pane": pane_title,
            "line": line,
        }

        if fragment:
            data["raw"] = fragment

            for candidate_type, pattern in EVENT_TYPE_PATTERNS:
                m = pattern.search(fragment)
                if not m:
                    continue
                event_type = candidate_type
                groups = [g.strip() for g in m.groups()]
                if candidate_type in {"full_received", "reset", "ready"}:
                    key = "bin" if candidate_type != "ready" else "truck"
                    data[key] = groups[0]
                elif candidate_type == "bin_level":
                    data["bin"] = groups[0]
                    data["level"] = int(groups[1])
                elif candidate_type in {"assigned", "refused", "completed", "working"}:
                    data["truck"] = groups[0]
                    data["bin"] = groups[1]
                elif candidate_type == "requesting":
                    data["truck"] = groups[0]
                    data["bin"] = groups[1]
                    data["mode"] = groups[2]
                break

        if event_type == "tmux_line":
            m = BIN_LEVEL_LINE_PATTERN.search(normalized_line)
            if m:
                event_type = "bin_level"
                data["bin"] = m.group(1).strip()
                data["level"] = int(m.group(2))

        if event_type == "tmux_line":
            m = BIN_ALERT_FULL_LINE_PATTERN.search(normalized_line)
            if m:
                event_type = "full_received"
                data["bin"] = m.group(1).strip()

        if event_type == "tmux_line":
            m = BIN_RESET_LINE_PATTERN.search(normalized_line)
            if m:
                event_type = "reset"
                data["bin"] = m.group(1).strip()

        return {
            "id": f"evt_{uuid.uuid4().hex[:10]}",
            "ts": datetime.now(UTC).isoformat(),
            "source": f"tmux:{pane_title}",
            "type": event_type,
            "severity": "info",
            "data": data,
            "raw": line,
        }
