from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException, status
from app.models.match import Match, MatchStatus
from app.models.user import User
from app.schemas.match import MatchCreate, MatchResult
from app.utils.scramble_generator import generate_scramble
import uuid
from datetime import datetime

class MatchService:
    def __init__(self, db: Session):
        self.db = db

    def create_match(self, player1_id: int, match_data: MatchCreate) -> Match:
        """Create a new match"""
        # Generate scramble
        scramble = generate_scramble()
        
        # If opponent_id is provided, create match with that user
        if match_data.opponent_id:
            player2_id = match_data.opponent_id
            # Verify opponent exists
            opponent = self.db.query(User).filter(User.id == player2_id).first()
            if not opponent:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Opponent not found"
                )
            if opponent.id == player1_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot play against yourself"
                )
        else:
            # Find random opponent (online users)
            opponent = self.db.query(User).filter(
                User.id != player1_id,
                User.is_online == True
            ).order_by(func.random()).first()
            
            if not opponent:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="No available opponents found"
                )
            player2_id = opponent.id
        
        # Create match
        match = Match(
            match_id=str(uuid.uuid4()),
            player1_id=player1_id,
            player2_id=player2_id,
            scramble=scramble,
            status=MatchStatus.waiting
        )
        
        self.db.add(match)
        self.db.commit()
        self.db.refresh(match)
        
        return match

    def find_opponent(self, player_id: int) -> Match:
        """Find a random opponent and create match"""
        match_data = MatchCreate(opponent_id=None)
        return self.create_match(player_id, match_data)

    def get_match(self, match_id: str) -> Match:
        """Get match by match_id"""
        match = self.db.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        return match

    def start_match(self, match_id: str, user_id: int) -> Match:
        """Start a match"""
        match = self.get_match(match_id)
        
        if user_id not in [match.player1_id, match.player2_id]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not a participant in this match"
            )
        
        if match.status != MatchStatus.waiting:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Match is not in waiting status"
            )
        
        match.status = MatchStatus.active
        match.started_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(match)
        
        return match

    def submit_result(self, match_id: str, user_id: int, solve_time: int) -> Match:
        """Submit solve time for a match"""
        match = self.get_match(match_id)
        
        if user_id not in [match.player1_id, match.player2_id]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not a participant in this match"
            )
        
        if match.status != MatchStatus.active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Match is not active"
            )
        
        # Update player time
        if user_id == match.player1_id:
            if match.player1_time is not None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Result already submitted"
                )
            match.player1_time = solve_time
        else:
            if match.player2_time is not None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Result already submitted"
                )
            match.player2_time = solve_time
        
        # Check if both players submitted
        if match.player1_time is not None and match.player2_time is not None:
            match.status = MatchStatus.completed
            match.completed_at = datetime.utcnow()
            
            # Determine winner (người có thời gian nhỏ hơn = nhanh hơn = thắng)
            if match.player1_time < match.player2_time:
                match.winner_id = match.player1_id
            elif match.player2_time < match.player1_time:
                match.winner_id = match.player2_id
            else:
                match.is_draw = True
            
            # Update user statistics
            self._update_user_stats(match)
        
        self.db.commit()
        self.db.refresh(match)
        
        return match

    def _update_user_stats(self, match: Match):
        """Update user statistics after match completion"""
        player1 = self.db.query(User).filter(User.id == match.player1_id).first()
        player2 = self.db.query(User).filter(User.id == match.player2_id).first()
        
        # Determine actual scores
        if match.is_draw:
            player1.total_draws += 1
            player2.total_draws += 1
            player1_score = 0.5
            player2_score = 0.5
        elif match.winner_id == match.player1_id:
            player1.total_wins += 1
            player2.total_losses += 1
            player1_score = 1.0
            player2_score = 0.0
        else:
            player1.total_losses += 1
            player2.total_wins += 1
            player1_score = 0.0
            player2_score = 1.0
        
        # Update ELO ratings
        self._update_elo_ratings(player1, player2, player1_score, player2_score)
        
        # Update average time and best time
        for player, time in [(player1, match.player1_time), (player2, match.player2_time)]:
            if time:
                # Update best time
                if player.best_time is None or time < player.best_time:
                    player.best_time = time
                
                # Update average time (simplified - should calculate from all matches)
                if player.average_time is None:
                    player.average_time = float(time) / 1000.0
                else:
                    # Simple moving average - convert Decimal to float for calculation
                    current_avg = float(player.average_time)
                    new_avg = (current_avg + (time / 1000.0)) / 2
                    player.average_time = new_avg
        
        self.db.commit()

    def _update_elo_ratings(self, player1: User, player2: User, player1_score: float, player2_score: float):
        """Update ELO ratings based on match result"""
        # Get current ratings (default to 1000 if None)
        rating1 = player1.elo_rating if player1.elo_rating else 1000
        rating2 = player2.elo_rating if player2.elo_rating else 1000
        
        # Calculate expected scores
        expected1 = 1 / (1 + 10 ** ((rating2 - rating1) / 400))
        expected2 = 1 / (1 + 10 ** ((rating1 - rating2) / 400))
        
        # Determine K factor (32 for new players, 24 for intermediate, 16 for experienced)
        def get_k_factor(rating):
            if rating < 1600:
                return 32
            elif rating < 2000:
                return 24
            else:
                return 16
        
        k1 = get_k_factor(rating1)
        k2 = get_k_factor(rating2)
        
        # Calculate new ratings
        new_rating1 = int(rating1 + k1 * (player1_score - expected1))
        new_rating2 = int(rating2 + k2 * (player2_score - expected2))
        
        # Update ratings (ensure minimum of 0)
        player1.elo_rating = max(0, new_rating1)
        player2.elo_rating = max(0, new_rating2)

