const std = @import("std");

const chess = @import("chess");

test "FEN Parsing" {
    const board = chess.parseFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");

    try std.testing.expectEqual(chess.Board{
        .pieces = .{
            .{ .bits = 0x00FF00000000FF00 },
            .{ .bits = 0x4200000000000042 },
            .{ .bits = 0x2400000000000024 },
            .{ .bits = 0x8100000000000081 },
            .{ .bits = 0x1000000000000010 },
            .{ .bits = 0x0800000000000008 },
        },
        .colours = .{ .{ .bits = 0x000000000000FFFF }, .{ .bits = 0xFFFF000000000000 } },
        .stm = .White,
        .half_moves = 0,
        .ep_square = null,
        .castling = .{ .{ .bits = 0x8100000000000000 }, .{ .bits = 0x81 } },
    }, board);
}
