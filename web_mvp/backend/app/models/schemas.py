from pydantic import BaseModel
from datetime import datetime
from typing import Literal


class OperationResponse(BaseModel):
    requestId: str
    action: Literal["start", "stop", "restart", "healthcheck"]
    status: Literal["accepted", "completed", "failed"]
    startedAt: datetime
    finishedAt: datetime | None = None
    exitCode: int | None = None
    message: str | None = None


class SystemStatus(BaseModel):
    service: str
    state: Literal["idle", "running", "failed"]
    session: str
    timestamp: datetime
