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
pub const Square = packed struct {
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

pub const MoveFlag = enum(u4) {
    Quiet = 0,
    DoublePawnPush = 1,
    CastleKing = 2,
    CastleQueen = 3,
    Capture = 4,
    EPCapture = 5,
    PromoKnight = 8,
    PromoBishop = 9,
    PromoRook = 10,
    PromoQueen = 11,
    PromoCaptureKnight = 12,
    PromoCaptureBishop = 13,
    PromoCaptureRook = 14,
    PromoCaptureQueen = 15,
};

pub const Move = packed struct {
    move_data: u16,

    pub inline fn from(self: Move) Square {
        return Square.fromIndex(self.move_data >> 10);
    }

    pub inline fn to(self: Move) Square {
        return Square.fromIndex((self.move_data >> 4) & 63);
    }

    pub inline fn moveFlag(self: Move) MoveFlag {
        return @enumFromInt(self.move_data & 15);
    }

    pub inline fn isPromotion(self: Move) bool {
        return @intFromEnum(self.moveFlag()) & 8 == 8;
    }

    pub inline fn isCapture(self: Move) bool {
        return @intFromEnum(self.moveFlag()) & 4 == 4;
    }

    pub inline fn promoteTo(self: Move) ?PieceType {
        if (!self.isPromotion()) return null;
        return switch (@intFromEnum(self.moveFlag()) & 3) {
            0 => .Knight,
            1 => .Bishop,
            2 => .Rook,
            3 => .Queen,
            else => unreachable,
        };
    }

    pub inline fn isCastle(self: Move) bool {
        return @intFromEnum(self.moveFlag()) & 14 == 2;
    }

    pub fn toAlgebraic(self: Move) []u8 {
        var buf: [5]u8 = undefined;
        const fromAlg = self.from().toAlgebraic();
        const toAlg = self.to().toAlgebraic();
        buf[0] = fromAlg[0];
        buf[1] = fromAlg[1];

        buf[2] = toAlg[0];
        buf[3] = toAlg[1];

        if (self.isPromotion()) {
            buf[4] = switch (@intFromEnum(self.moveFlag()) & 3) {
                0 => 'q',
                1 => 'r',
                2 => 'b',
                3 => 'n',
                else => '?',
            };
            return buf[0..5];
        }
        return buf[0..4];
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
    mailbox: [64]?Piece,
    pieces: [6]Bitboard,
    colours: [2]Bitboard,
    ep_square: ?Square,
    castling: [2]u8,
    half_moves: u16,
    stm: Color,

    pub fn pieceAt(self: Board, sq: Square) ?Piece {
        return self.mailbox[sq.toIndex()];
    }

    pub inline fn empty() Board {
        return .{
            .mailbox = @splat(null),
            .pieces = @splat(Bitboard.empty()),
            .colours = @splat(Bitboard.empty()),
            .stm = .White,
            .half_moves = 0,
            .ep_square = null,
            .castling = .{ 0, 0 },
        };
    }

    pub fn setPiece(self: *Board, piece: Piece) void {
        self.pieces[@intFromEnum(piece.piece_type)].setSq(piece.location.?);
        self.colours[@intFromEnum(piece.color)].setSq(piece.location.?);
        self.mailbox[piece.location.?.toIndex()] = piece;
    }

    pub fn removePiece(self: *Board, piece: Piece) void {
        self.pieces[@intFromEnum(piece.piece_type)].clearSq(piece.location.?);
        self.colours[@intFromEnum(piece.color)].clearSq(piece.location.?);
        self.mailbox[piece.location.?.toIndex()] = null;
    }
};

pub const MoveList = struct {
    moves: [256]Move,
    count: u8,

    pub fn init() MoveList {
        return MoveList{ .moves = @splat(.{
            .from = .{ .file = 0, .rank = 0 },
            .to = .{ .file = 0, .rank = 0 },
            .move_flag = .Quiet,
        }), .count = 0 };
    }

    pub fn addMove(self: *MoveList, move: Move) void {
        self.moves[@as(u8, self.count)] = move;
        self.count += 1;
    }
};
