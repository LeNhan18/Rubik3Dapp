import random

# WCA scramble notation moves
MOVES = ['R', 'L', 'U', 'D', 'F', 'B']
PRIME = "'"
DOUBLE = "2"

def generate_scramble(length: int = 3) -> str:
    """Generate a random WCA-compliant scramble"""
    scramble = []
    last_move = None
    
    for _ in range(length):
        # Choose a move that's different from the last one
        move = random.choice(MOVES)
        while move == last_move:
            move = random.choice(MOVES)
        
        # Randomly add prime or double
        modifier = random.choice(['', PRIME, DOUBLE])
        scramble.append(move + modifier)
        
        last_move = move
    
    return ' '.join(scramble)

