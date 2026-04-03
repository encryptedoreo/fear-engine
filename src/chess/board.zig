const std = @import("std");

const types = @import("types.zig");

pub fn parseFEN(fen: []const u8) types.Board {
    var tokens = std.mem.tokenizeAny(u8, fen, &std.ascii.whitespace);
    var board: types.Board = .empty();

    var i: usize = 63; // decrement counter
    for (tokens.next().?) |c| {
        if (c == '/') continue;
        if (std.ascii.isDigit(c)) {
            i -= c - '0';
            continue;
        }

        const sq: types.Square = .fromIndex(i ^ 7); // flip rank to account for traversing FEN in reverse order
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
        board.castling[color] |= @as(u8, 1) << std.math.cast(u3, rook_file).?;
    }

    board.ep_square = .fromAlgebraic(tokens.next().?);
    board.half_moves = std.fmt.parseInt(u16, tokens.next().?, 10) catch 0;

    return board;
}

pub fn makeMove(board: *types.Board, move: types.Move) void {
    var piece = board.pieceAt(move.from()) orelse return;
    board.removePiece(move.from());

    board.stm = board.stm.opposite();
    board.half_moves = if (piece.piece_type == .Pawn or move.isCapture()) @as(u16, 0) else board.half_moves + 1;

    if (move.isCastle()) {
        // the king always ends up of the c- and g- files after queenside and kingside
        // castling respectively, so we can just set the location of the king accordingly
        piece.location = .{ .file = if (move.moveFlag() == .CastleKing) @as(u3, 6) else @as(u3, 2), .rank = move.from().rank };
        board.setPiece(piece);

        // `board.castling[piece.color]` should only ever have 2 bits set at most, so we can
        // use `@ctz` and `@clz` to find the file of the queenside and kingside rooks; in the
        // event that there is only one bit set, these are equivalent
        const rook_file = blk: {
            if (move.moveFlag() == .CastleKing) break :blk @ctz(board.castling[@intFromEnum(piece.color)]);
            break :blk 7 - @clz(board.castling[@intFromEnum(piece.color)]);
        };

        board.removePiece(.{
            .file = std.math.cast(u3, rook_file).?,
            .rank = move.from().rank,
        });

        board.setPiece(.{
            .piece_type = .Rook,
            .color = piece.color,
            .location = .{ .file = if (move.moveFlag() == .CastleKing) @as(u3, 5) else @as(u3, 3), .rank = move.from().rank },
        });
    } else {
        // remove castling rights if the king or a rook moves accordingly
        if (piece.piece_type == .King) board.castling[@intFromEnum(piece.color)] = 0 else if (piece.piece_type == .Rook and
            move.from().rank == if (piece.color == .White) @as(u3, 0) else @as(u3, 7)) board.castling[@intFromEnum(piece.color)] &= ~(@as(u8, 1) << std.math.cast(u3, move.from().file).?);

        piece.location = move.to();
        if (move.isPromotion()) piece.piece_type = move.promoteTo().?;
        if (move.moveFlag() == .EPCapture) board.removePiece(.{
            .file = board.ep_square.?.file,
            .rank = if (move.from().rank == 6) @as(u3, 5) else @as(u3, 2),
        });

        board.setPiece(piece);

        board.ep_square = if (move.moveFlag() == .DoublePawnPush) .{
            .file = move.from().file,
            .rank = if (move.from().rank == 6) @as(u3, 5) else @as(u3, 2),
        } else null;
    }
}
