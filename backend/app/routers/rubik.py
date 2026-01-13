from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from app.database import get_db
from app.utils.dependencies import get_current_user

# Try to import kociemba, but make it optional
try:
    import kociemba
    KOCIEMBA_AVAILABLE = True
except ImportError:
    KOCIEMBA_AVAILABLE = False
    print("WARNING: kociemba module not available. Install it with: pip install kociemba")
    print("Note: kociemba requires Microsoft Visual C++ Build Tools on Windows")

router = APIRouter()

# In-memory storage cho solutions (có thể thay bằng database sau)
_solutions_storage: dict[int, dict] = {}  # {solution_id: solution_data}
_solution_counter = 0


class CubeStateRequest(BaseModel):
    """Request model cho cube state - Kociemba format (54 characters)"""
    cube_state: str  # 54 characters: URFDLB (6 faces x 9 stickers)
    
    class Config:
        json_schema_extra = {
            "example": {
                "cube_state": "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB"
            }
        }


class SolveResponse(BaseModel):
    """Response model cho solution"""
    solution: str  # Kociemba solution format (e.g., "R U R' U'")
    moves: List[str]  # List of moves (e.g., ["R", "U", "R'", "U'"])
    move_count: int  # Số lượng moves


@router.post("/solve", response_model=SolveResponse)
async def solve_cube(request: CubeStateRequest):
    """
    Giải Rubik's Cube sử dụng Kociemba algorithm
    
    Input: Cube state dạng Kociemba (54 characters)
    - Format: URFDLB (Up, Right, Front, Down, Left, Back)
    - Mỗi face: 9 characters (3x3 grid)
    - Colors: U=Up, R=Right, F=Front, D=Down, L=Left, B=Back
    
    Output: Solution string và list of moves
    """
    cube_state = request.cube_state.strip().upper()
    
    # Validate input
    if len(cube_state) != 54:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid cube state length. Expected 54 characters, got {len(cube_state)}"
        )
    
    # Validate characters (chỉ cho phép U, R, F, D, L, B)
    valid_chars = set('URFDLB')
    if not all(c in valid_chars for c in cube_state):
        invalid_chars = set(cube_state) - valid_chars
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid characters in cube state: {invalid_chars}. Only U, R, F, D, L, B are allowed"
        )
    
    if not KOCIEMBA_AVAILABLE:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Kociemba solver is not available. Please install kociemba package."
        )
    
    try:
        # Gọi kociemba.solve() - thư viện Python chính thức
        solution = kociemba.solve(cube_state)
        
        # Parse solution thành list of moves
        # Kociemba format: "R U R' U'" hoặc "R U R' U' R2" (space-separated)
        moves = solution.split() if solution else []
        
        return SolveResponse(
            solution=solution,
            moves=moves,
            move_count=len(moves)
        )
        
    except ValueError as e:
        # Kociemba throws ValueError nếu cube state không hợp lệ
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid cube state: {str(e)}"
        )
    except Exception as e:
        # Các lỗi khác
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error solving cube: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "solver": "kociemba"}


# ========== HINT ENDPOINT ==========
class HintRequest(BaseModel):
    """Request model cho hint"""
    cube_state: str = Field(..., description="Cube state dạng Kociemba (54 characters)")
    n_moves: int = Field(default=1, ge=1, le=5, description="Số moves muốn hint (1-5)")


class HintResponse(BaseModel):
    """Response model cho hint"""
    hint: List[str]  # List of hint moves
    move_count: int


@router.post("/hint", response_model=HintResponse)
async def get_hint(request: HintRequest):
    """
    Lấy hint (gợi ý moves) cho Rubik's Cube
    
    Trả về n_moves đầu tiên của solution
    """
    cube_state = request.cube_state.strip().upper()
    n_moves = request.n_moves
    
    # Validate input
    if len(cube_state) != 54:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid cube state length. Expected 54 characters, got {len(cube_state)}"
        )
    
    valid_chars = set('URFDLB')
    if not all(c in valid_chars for c in cube_state):
        invalid_chars = set(cube_state) - valid_chars
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid characters in cube state: {invalid_chars}"
        )
    
    if not KOCIEMBA_AVAILABLE:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Kociemba solver is not available. Please install kociemba package."
        )
    
    try:
        # Giải cube để lấy solution
        solution = kociemba.solve(cube_state)
        moves = solution.split() if solution else []
        
        # Lấy n_moves đầu tiên
        hint_moves = moves[:n_moves] if len(moves) >= n_moves else moves
        
        return HintResponse(
            hint=hint_moves,
            move_count=len(hint_moves)
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid cube state: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting hint: {str(e)}"
        )


# ========== VALIDATE ENDPOINT ==========
class ValidateRequest(BaseModel):
    """Request model để validate cube state"""
    cube_state: str = Field(..., description="Cube state dạng Kociemba (54 characters)")


class ValidateResponse(BaseModel):
    """Response model cho validation"""
    is_valid: bool
    message: str
    can_solve: Optional[bool] = None  # None nếu không thể kiểm tra


@router.post("/validate", response_model=ValidateResponse)
async def validate_cube_state(request: ValidateRequest):
    """
    Validate cube state có hợp lệ không
    
    Kiểm tra:
    - Độ dài = 54
    - Chỉ chứa U, R, F, D, L, B
    - Có thể giải được (nếu có thể)
    """
    cube_state = request.cube_state.strip().upper()
    
    # Check length
    if len(cube_state) != 54:
        return ValidateResponse(
            is_valid=False,
            message=f"Invalid length: {len(cube_state)} (expected 54)"
        )
    
    # Check characters
    valid_chars = set('URFDLB')
    invalid_chars = set(cube_state) - valid_chars
    if invalid_chars:
        return ValidateResponse(
            is_valid=False,
            message=f"Invalid characters: {invalid_chars}"
        )
    
    if not KOCIEMBA_AVAILABLE:
        return ValidateResponse(
            is_valid=True,
            message="Cube state format is valid (cannot verify solvability - kociemba not available)",
            can_solve=None
        )
    
    # Try to solve (check if solvable)
    try:
        kociemba.solve(cube_state)
        return ValidateResponse(
            is_valid=True,
            message="Cube state is valid and solvable",
            can_solve=True
        )
    except ValueError as e:
        return ValidateResponse(
            is_valid=False,
            message=f"Cube state is invalid: {str(e)}",
            can_solve=False
        )
    except Exception:
        return ValidateResponse(
            is_valid=True,
            message="Cube state format is valid (cannot verify solvability)",
            can_solve=None
        )


# ========== SOLUTION HISTORY ENDPOINTS ==========
class SolutionCreate(BaseModel):
    """Request model để lưu solution"""
    cube_state: str = Field(..., description="Cube state ban đầu")
    solution: str = Field(..., description="Solution string")
    moves: List[str] = Field(..., description="List of moves")
    notes: Optional[str] = Field(None, description="Ghi chú")


class SolutionResponse(BaseModel):
    """Response model cho solution"""
    id: int
    cube_state: str
    solution: str
    moves: List[str]
    move_count: int
    notes: Optional[str]
    created_at: datetime


@router.post("/solutions", response_model=SolutionResponse, status_code=status.HTTP_201_CREATED)
async def save_solution(
    solution_data: SolutionCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Lưu solution vào history (in-memory storage)
    
    Note: Trong production nên dùng database
    """
    global _solution_counter
    
    _solution_counter += 1
    solution_id = _solution_counter
    
    solution_record = {
        "id": solution_id,
        "user_id": current_user["id"],
        "cube_state": solution_data.cube_state,
        "solution": solution_data.solution,
        "moves": solution_data.moves,
        "move_count": len(solution_data.moves),
        "notes": solution_data.notes,
        "created_at": datetime.now()
    }
    
    _solutions_storage[solution_id] = solution_record
    
    return SolutionResponse(**solution_record)


@router.get("/solutions", response_model=List[SolutionResponse])
async def get_solutions(
    current_user: dict = Depends(get_current_user),
    limit: int = 20,
    offset: int = 0
):
    """
    Lấy danh sách solutions của user hiện tại
    
    Sắp xếp theo thời gian tạo (mới nhất trước)
    """
    user_solutions = [
        sol for sol in _solutions_storage.values()
        if sol["user_id"] == current_user["id"]
    ]
    
    # Sort by created_at (newest first)
    user_solutions.sort(key=lambda x: x["created_at"], reverse=True)
    
    # Pagination
    paginated = user_solutions[offset:offset + limit]
    
    return [SolutionResponse(**sol) for sol in paginated]


@router.get("/solutions/{solution_id}", response_model=SolutionResponse)
async def get_solution(
    solution_id: int,
    current_user: dict = Depends(get_current_user)
):
    """
    Lấy một solution cụ thể theo ID
    """
    if solution_id not in _solutions_storage:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solution not found"
        )
    
    solution = _solutions_storage[solution_id]
    
    # Check ownership
    if solution["user_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to access this solution"
        )
    
    return SolutionResponse(**solution)


@router.put("/solutions/{solution_id}", response_model=SolutionResponse)
async def update_solution(
    solution_id: int,
    solution_update: SolutionCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Update một solution (chỉ có thể update notes)
    """
    if solution_id not in _solutions_storage:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solution not found"
        )
    
    solution = _solutions_storage[solution_id]
    
    # Check ownership
    if solution["user_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to update this solution"
        )
    
    # Update (chỉ update notes và solution nếu muốn)
    solution["notes"] = solution_update.notes
    if solution_update.solution:
        solution["solution"] = solution_update.solution
        solution["moves"] = solution_update.moves
        solution["move_count"] = len(solution_update.moves)
    
    return SolutionResponse(**solution)


@router.delete("/solutions/{solution_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_solution(
    solution_id: int,
    current_user: dict = Depends(get_current_user)
):
    """
    Xóa một solution
    """
    if solution_id not in _solutions_storage:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solution not found"
        )
    
    solution = _solutions_storage[solution_id]
    
    # Check ownership
    if solution["user_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete this solution"
        )
    
    del _solutions_storage[solution_id]
    return None


@router.delete("/solutions", status_code=status.HTTP_204_NO_CONTENT)
async def delete_all_solutions(
    current_user: dict = Depends(get_current_user)
):
    """
    Xóa tất cả solutions của user hiện tại
    """
    solution_ids_to_delete = [
        sol_id for sol_id, sol in _solutions_storage.items()
        if sol["user_id"] == current_user["id"]
    ]
    
    for sol_id in solution_ids_to_delete:
        del _solutions_storage[sol_id]
    
    return None
