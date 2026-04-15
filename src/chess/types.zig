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

    pub inline fn to0x88(self: Square) u8 {
        return @as(u8, self.rank) * 16 + @as(u8, self.file);
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

pub const Board = struct {
    mailbox: [64]u8 align(64),
    ep_square: ?Square,
    castling: [2]u8,
    half_moves: u16,
    stm: Color,

    pub fn pieceAt(self: Board, sq: Square) ?Piece {
        const piece = self.mailbox[sq.toIndex()];
        if (piece == 0) return null;
        return .{
            .piece_type = switch (piece & 31) {
                1, 2 => .Pawn,
                4 => .Knight,
                8 => .Bishop,
                16 => .Rook,
                24 => .Queen,
                32 => .King,
                else => unreachable,
            },
            .color = if (piece & 128 == 128) .Black else .White,
            .location = sq,
        };
    }

    pub inline fn empty() Board {
        return .{
            .mailbox = @splat(0),
            .stm = .White,
            .half_moves = 0,
            .ep_square = null,
            .castling = .{ 0, 0 },
        };
    }

    pub fn setPiece(self: *Board, piece: Piece) void {
        var new_piece: u8 = 0;

        if (piece.color == .Black) new_piece |= 128;
        new_piece |= switch (piece.piece_type) {
            .Pawn => if (piece.color == .White) 0b00000001 else 0b00000010,
            .Knight => 0b00000100,
            .Bishop => 0b00001000,
            .Rook => 0b00010000,
            .Queen => 0b00011000,
            .King => 0b00100000,
        };

        self.mailbox[piece.location.?.toIndex()] = new_piece;
    }

    pub fn removePiece(self: *Board, location: Square) void {
        self.mailbox[location.toIndex()] = 0;
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
