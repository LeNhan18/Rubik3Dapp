from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.match import MatchCreate, MatchResponse, MatchResult
from app.services.match_service import MatchService
from app.utils.dependencies import get_current_user

router = APIRouter()

@router.post("/create", response_model=MatchResponse)
async def create_match(
    match_data: MatchCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new match (with friend or random opponent)"""
    service = MatchService(db)
    match = service.create_match(current_user["id"], match_data)
    return match

@router.post("/find-opponent", response_model=MatchResponse)
async def find_opponent(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Find a random opponent and create match"""
    service = MatchService(db)
    match = service.find_opponent(current_user["id"])
    return match

@router.get("/{match_id}", response_model=MatchResponse)
async def get_match(
    match_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get match information"""
    service = MatchService(db)
    match = service.get_match(match_id)
    
    # Verify user is a participant
    if current_user["id"] not in [match.player1_id, match.player2_id]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not a participant in this match"
        )
    
    return match

@router.post("/{match_id}/start", response_model=MatchResponse)
async def start_match(
    match_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Start a match"""
    service = MatchService(db)
    match = service.start_match(match_id, current_user["id"])
    return match

@router.post("/{match_id}/submit-result", response_model=MatchResponse)
async def submit_result(
    match_id: str,
    result: MatchResult,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit solve time for a match"""
    service = MatchService(db)
    match = service.submit_result(match_id, current_user["id"], result.solve_time)
    return match

@router.get("/", response_model=list[MatchResponse])
async def get_my_matches(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    status_filter: str = None,
    limit: int = 20
):
    """Get user's matches"""
    from app.models.match import Match, MatchStatus
    
    query = db.query(Match).filter(
        (Match.player1_id == current_user["id"]) | (Match.player2_id == current_user["id"])
    )
    
    if status_filter:
        try:
            status_enum = MatchStatus[status_filter]
            query = query.filter(Match.status == status_enum)
        except KeyError:
            pass
    
    matches = query.order_by(Match.created_at.desc()).limit(limit).all()
    return matches

