# Supernova
A UCI chess engine written in Zig.

## Roadmap
### Board Representation
- [x] Represent the board
- [x] Represent the pieces
- [x] Read a position from an FEN-string
- [x] Keep the current state of the game
- [ ] Implement Zobrist hashing
- [ ] Create functions to control the board
- [x] Create functions to get information from the board

### Move Generator
- [ ] Teach the move generator how the pieces move
- [ ] Create a move format
- [ ] Generate moves for all the pieces when the MG is given a position
- [ ] Take special moves into account (such as castling)
- [ ] Add generated moves to a move list and returns this when done
- [ ] Can generate captures and silent moves separately
- [ ] Can determine if a square is attacked
- [ ] Add perft (performance testing)
  - [ ] Add a perft function that runs on a given position
  - [ ] Run through a perft suite containing "tricky" positions
- [ ] **Milestone 1: Move generator is bug-free**

### Search Functionality
- [ ] Structs (information) needed by the search
- [ ] Write the iterative deepening function
- [ ] Write the Alpha-Beta function
- [ ] Write the Quiescence search
- [ ] Make fixed search possible (on ply, nodes, or time)
- [ ] Implement time management for non-fixed searches
- [ ] Helper functions such as determining if a position is draw

### Evaluation Function
- [ ] Material counting
- [ ] Piece Square tables (PST or PSQT)

### Move Ordering
- [ ] MVV-LVA (Most Valuable Victim-Least Valuable Attacker)

### Communication Interface
- [ ] Write the UCI-protocol
- [ ] Write the XBoard protocol (optional)
- [ ] Make sure the engine understands the commands
- [ ] Make sure the engine reacts correctly
- [ ] **Milestone 2: Baseline is done. 1500-1700 Elo**

### Advanced Features
- [ ] Transposition table
- [ ] TT move ordering
- [ ] Principal Variation Search
- [ ] Killer moves
- [ ] Tapered Evaluation
- [ ] Texel tuning
- [ ] **Milestone 3: Engine should be >= 2000 Elo**

### Optimization & Enhancement
- [ ] History heuristics
- [ ] Pruning capability
  - [ ] Null move pruning
  - [ ] Futility pruning
  - [ ] Mate pruning
- [ ] Multithreaded search
- [ ] Evaluation enhancements
  - [ ] Mobility
  - [ ] King safety
  - [ ] Passed pawns
  - [ ] General knowledge
  - [ ] NNUE
