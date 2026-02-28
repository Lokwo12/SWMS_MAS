from fastapi import APIRouter, HTTPException
from app.models.schemas import OperationResponse, SystemStatus
from app.services.orchestrator import get_status, run_action


router = APIRouter(prefix="/api/v1/system", tags=["system"])


@router.get("/status", response_model=SystemStatus)
def status() -> SystemStatus:
    return get_status()


@router.post("/start", response_model=OperationResponse)
def start() -> OperationResponse:
    return run_action("start")


@router.post("/stop", response_model=OperationResponse)
def stop() -> OperationResponse:
    return run_action("stop")


@router.post("/restart", response_model=OperationResponse)
def restart() -> OperationResponse:
    return run_action("restart")


@router.post("/healthcheck", response_model=OperationResponse)
def healthcheck() -> OperationResponse:
    try:
        return run_action("healthcheck")
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
