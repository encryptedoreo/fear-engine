const std = @import("std");

const types = @import("types.zig");

pub fn parseFEN(fen: []const u8) types.Board {
    var tokens = std.mem.tokenizeAny(u8, fen, &std.ascii.whitespace);
    var board: types.Board = .empty();

    var i: usize = 63;
    for (tokens.next().?) |c| {
        if (c == '/') continue;
        if (std.ascii.isDigit(c)) {
            i -= c - '0';
            continue;
        }

        const sq: types.Square = .fromIndex(i);
        const color: types.Color = if (std.ascii.isUpper(c)) .White else .Black;
        const piece_type: types.PieceType = switch (std.ascii.toLower(c)) {
            'p' => .Pawn,
            'n' => .Knight,
            'b' => .Bishop,
            'r' => .Rook,
            'q' => .Queen,
            'k' => .King,
            else => unreachable,
        };

        board.setPiece(.{
            .piece_type = piece_type,
            .color = color,
            .location = sq,
        });

        if (i > 0) i -= 1;
    }

    board.stm = if (std.mem.eql(u8, tokens.next().?, "w")) .White else .Black;

    for (tokens.next().?) |c| {
        if (c == '-') break;
        const color = @intFromBool(std.ascii.isUpper(c));
        const rook_file = switch (c) {
            'K', 'k' => 7,
            'Q', 'q' => 0,
            else => std.ascii.toLower(c) - 'a',
        };
        board.castling[color].setSq(.{ .file = std.math.cast(u3, rook_file).?, .rank = if (color == 0) 7 else 0 });
    }

    board.ep_square = .fromAlgebraic(tokens.next().?);
    board.half_moves = std.fmt.parseInt(u16, tokens.next().?, 10) catch 0;

    return board;
}

pub fn makeMove(board: *types.Board, move: types.Move) void {
    const piece = board.pieceAt(move.from);
    if (piece == null) return board;

    new_board.clearSquare(mv.from);
    new_board.setSquare(mv.to, piece.?);

    if (mv.isPromotion()) {
        new_board.setSquare(mv.to, .{ .piece_type = mv.promotion.?, .color = piece.?.color, .location = mv.to });
    }

    new_board.stm = board.stm.opposite();

    return new_board;
}
