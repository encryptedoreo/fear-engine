const std = @import("std");

pub const PieceType = enum { Pawn, Knight, Bishop, Rook, Queen, King };
pub const Color = enum {
    White,
    Black,

    pub fn opposite(self: Color) Color {
        return switch (self) {
            .White => .Black,
            .Black => .White,
        };
    }
};

pub const Piece = struct { piece_type: PieceType, color: Color, location: ?Square };
pub const Square = struct {
    file: u3,
    rank: u3,

    pub inline fn toIndex(self: Square) usize {
        return @as(usize, self.rank) * 8 + @as(usize, self.file);
    }

    pub inline fn toAlgebraic(self: Square) []const u8 {
        return &[_]u8{ 'a' + @as(u8, self.file), '1' + @as(u8, self.rank) };
    }

    pub fn fromIndex(index: usize) Square {
        return .{
            .file = std.math.cast(u3, index % 8).?,
            .rank = std.math.cast(u3, index / 8).?,
        };
    }

    pub fn fromAlgebraic(s: []const u8) ?Square {
        if (s.len != 2) return null;
        return .{ .file = std.math.cast(u3, s[0] - 'a').?, .rank = std.math.cast(u3, s[1] - '1').? };
    }
};

pub const Move = packed struct {
    from: Square,
    to: Square,
    promotion: ?PieceType,

    pub inline fn isPromotion(self: Move) bool {
        return self.promotion != null;
    }

    pub fn toAlgebraic(self: Move) []u8 {
        var buf: [5]u8 = undefined;
        const fromAlg = self.from.toAlgebraic();
        const toAlg = self.to.toAlgebraic();
        buf[0] = fromAlg[0];
        buf[1] = fromAlg[1];

        buf[2] = toAlg[0];
        buf[3] = toAlg[1];

        if (self.isPromotion()) {
            buf[4] = switch (self.promotion.?) {
                .Queen => 'q',
                .Rook => 'r',
                .Bishop => 'b',
                .Knight => 'n',
                else => '?',
            };
            return buf[0..5];
        }
        return buf[0..4];
    }

    pub fn fromAlgebraic(s: []const u8) ?Move {
        if (s.len < 4) return null;
        const fromSq = Square.fromAlgebraic(s[0..2]).?;
        const toSq = Square.fromAlgebraic(s[2..4]).?;

        var promotion: ?PieceType = null;
        if (s.len == 5) {
            promotion = switch (s[4]) {
                'q' => .Queen,
                'r' => .Rook,
                'b' => .Bishop,
                'n' => .Knight,
                else => return null,
            };
        }

        return .{ .from = fromSq, .to = toSq, .promotion = promotion };
    }
};

pub const Bitboard = struct {
    bits: u64,

    pub inline fn empty() Bitboard {
        return .{ .bits = 0 };
    }

    pub inline fn full() Bitboard {
        return .empty().inverse();
    }

    pub inline fn fromSq(sq: Square) Bitboard {
        return .{ .bits = @as(u64, 1) << std.math.cast(u6, sq.toIndex()).? };
    }

    pub inline fn orWith(self: Bitboard, other: Bitboard) Bitboard {
        return .{ .bits = self.bits | other.bits };
    }

    pub inline fn andWith(self: Bitboard, other: Bitboard) Bitboard {
        return .{ .bits = self.bits & other.bits };
    }

    pub inline fn without(self: Bitboard, other: Bitboard) Bitboard {
        return .{ .bits = self.bits & ~other.bits };
    }

    pub inline fn has(self: Bitboard, sq: Square) bool {
        return self.andWith(.fromSq(sq)).bits != @as(u64, 0);
    }

    pub inline fn count(self: Bitboard) u6 {
        return @popCount(self.bits);
    }

    pub inline fn inverse(self: Bitboard) Bitboard {
        return .{ .bits = ~self.bits };
    }

    pub fn setSq(self: *Bitboard, sq: Square) void {
        self.bits |= @as(u64, 1) << std.math.cast(u6, sq.toIndex()).?;
    }

    pub fn clearSq(self: *Bitboard, sq: Square) void {
        self.bits &= ~(@as(u64, 1) << std.math.cast(u6, sq.toIndex()).?);
    }
};

pub const Board = struct {
    pieces: [6]Bitboard,
    colours: [2]Bitboard,
    ep_square: ?Square,
    castling: [2]Bitboard,
    half_moves: u16,
    stm: Color,

    pub fn pieceAt(self: Board, sq: Square) ?Piece {
        inline for (0..6, self.pieces) |i, bb| if (bb.has(sq)) return .{
            .piece_type = @enumFromInt(i),
            .color = if (self.colours[0].has(sq)) .White else .Black,
            .location = sq,
        };
        return null;
    }

    pub inline fn empty() Board {
        return .{
            .pieces = @splat(Bitboard.empty()),
            .colours = @splat(Bitboard.empty()),
            .stm = .White,
            .half_moves = 0,
            .ep_square = null,
            .castling = @splat(Bitboard.empty()),
        };
    }

    pub fn setPiece(self: *Board, piece: Piece) void {
        self.pieces[@intFromEnum(piece.piece_type)].setSq(piece.location.?);
        self.colours[@intFromEnum(piece.color)].setSq(piece.location.?);
    }
};
