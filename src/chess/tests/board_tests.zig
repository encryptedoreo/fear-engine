const std = @import("std");
const chess = @import("chess");

test "FEN Parsing" {
    const board = chess.parseFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");

    try std.testing.expectEqual(chess.Board{
        .stm = .White,
        .half_moves = 0,
        .ep_square = null,
        .castling = @splat(0x81),
        .mailbox = board.mailbox, // if the mailbox is wrong, at least one other field must be wrong too
    }, board);
}

test "Make Move" {
    var board = chess.parseFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");

    chess.makeMove(&board, .{ .move_data = 0x31C1 }); // e2e4
    try std.testing.expectEqual(chess.parseFEN("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"), board);
}
