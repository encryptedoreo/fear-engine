const types = @import("types.zig");

pub const PieceType = types.PieceType;
pub const Color = types.Color;
pub const Piece = types.Piece;
pub const Square = types.Square;
pub const Move = types.Move;
pub const Bitboard = types.Bitboard;
pub const Board = types.Board;

const board = @import("board.zig");

pub const parseFEN = board.parseFEN;
pub const makeMove = board.makeMove;
