const std = @import("std");

pub const Board = struct {
    points: [24]Point,
    bar: [2]u8,
    bearOff: [2]u8,

    const Self = @This();

    pub fn init() Board {
        return Board{
            .points = [_]Point{.{ .player = null, .count = 0 }} ** 24,
            .bar = [2]u8{ 0, 0 },
            .bearOff = [2]u8{ 0, 0 },
        };
    }

    pub fn movePiece(self: *Self, from: u8, to: u8) void {
        if (from == 25) {
            self.bar[self.points[to].player.?.color] -= 1;
        } else {
            self.points[from].count -= 1;
            if (self.points[from].count == 0) self.points[from].player = null;
        }

        if (to == 0 or to == 25) {
            self.bearOff[self.points[from].player.?.color] += 1;
        } else {
            if (self.points[to].player == null) {
                self.points[to].player = self.points[from].player;
            }
            self.points[to].count += 1;
        }
    }

    // Set the bpard for various game types. Will be expanded later
    pub fn dressBoard(self: *Self, players: [2]Player) void {
        // Keep the existing implementation, but adjust indices
        self.points[0] = Point{ .player = players[0], .count = 2 };
        self.points[11] = Point{ .player = players[0], .count = 5 };
        self.points[16] = Point{ .player = players[0], .count = 3 };
        self.points[18] = Point{ .player = players[0], .count = 5 };

        self.points[5] = Point{ .player = players[1], .count = 5 };
        self.points[7] = Point{ .player = players[1], .count = 3 };
        self.points[12] = Point{ .player = players[1], .count = 5 };
        self.points[23] = Point{ .player = players[1], .count = 2 };
    }
};

const Point = struct {
    player: Player,
    count: u8,
};

pub const Player = struct {
    name: []const u8,
    color: usize,
    score: usize,

    const Self = @This();

    pub fn init(name: []const u8, color: usize) Player {
        return Player{ .name = name, .color = color, .score = 0 };
    }
};

pub const GameState = struct {
    board: Board,
    players: [2]Player,
    currentPlayer: Player,
    dice: [2]u8,

    const Self = @This();

    pub fn init(name0: []const u8, name1: []const u8) GameState {
        const players = [2]Player{ Player.init(name0, 0), Player.init(name1, 1) };
        const board = Board.init();
        board.dressBoard(players);

        return GameState{
            .board = board,
            .players = players,
            .currentPlayer = players[0],
            .dice = [2]u8{ undefined, undefined },
        };
    }

    // roll 2 dice
    // TODO: Needs test case(s)
    pub fn rollDice(self: *Self) void {
        var prng = std.rand.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.os.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        const rand = prng.random();

        self.dice = .{ rand.intRangeAtMost(u8, 1, 6), rand.intRangeAtMost(u8, 1, 6) };
    }
};

pub const RulesEngine = struct {
    // determine whether a move is valid by checking whether the specific move is in the moves hashmap for the entire board
    // TODO: Needs test case(s)
    pub fn isValidMove(from: Point, to: Point, validMovesHash: std.AutoHashMap(Point, []Point)) bool {
        if (validMovesHash.contains(from)) {
            const moveList = validMovesHash.get(from);
            if (std.mem.containsAtLeast(Point, moveList, 1, to)) {
                return true;
            }
        }

        return false;
    }

    // check whether the game is over if player pieces are off the board
    pub fn isGameOver(gameState: *GameState) bool {
        return (gameState.board.bearOff[0] == 15 or gameState.board.bearOff[1] == 15);
    }

    // which player won
    pub fn getWinner(gameState: *GameState) Player {
        var player: Player = undefined;
        if (gameState.board.points[0].count == 15) {
            player = gameState.players[0];
        } else if (gameState.board.points[24].count == 15) {
            player = gameState.players[1];
        }
        return player;
    }

    // create a hashmap with all possible moves for all points owned by the current player
    // TODO: Needs test case(s)
    pub fn getAllValidMoves(gameState: *GameState, allocator: std.mem.Allocator) !std.AutoHashMap(u8, []u8) {
        var moves = std.AutoHashMap(u8, []u8).init(allocator);
        errdefer moves.deinit();

        const isDouble = gameState.dice[0] == gameState.dice[1];
        const movesCount = if (isDouble) 4 else 2;
        const playerIndex = gameState.currentPlayer.color;

        // Check if the player has pieces on the bar
        if (gameState.board.bar[playerIndex] > 0) {
            var possibleMoves = std.ArrayList(u8).init(allocator);
            defer possibleMoves.deinit();

            for (0..movesCount) |j| {
                const targetIndex = if (playerIndex == 0) gameState.dice[j % 2] - 1 else 24 - gameState.dice[j % 2];
                if (canMove(gameState.currentPlayer, gameState.board.points[targetIndex])) {
                    try possibleMoves.append(@as(u8, @intCast(targetIndex)));
                }
            }

            if (possibleMoves.items.len > 0) {
                try moves.put(25, try possibleMoves.toOwnedSlice());
            }
            return moves;
        }

        // Regular move generation
        const direction: i8 = if (playerIndex == 0) 1 else -1;
        for (gameState.board.points, 0..) |point, i| {
            if (point.player == gameState.currentPlayer) {
                var possibleMoves = std.ArrayList(u8).init(allocator);
                defer possibleMoves.deinit();

                for (0..movesCount) |j| {
                    const targetIndex = @as(i8, @intCast(i)) + direction * @as(i8, @intCast(gameState.dice[j % 2]));
                    if (targetIndex >= 0 and targetIndex < 24) {
                        const targetPoint = gameState.board.points[@as(usize, @intCast(targetIndex))];
                        if (canMove(gameState.currentPlayer, targetPoint)) {
                            try possibleMoves.append(@as(u8, @intCast(targetIndex)));
                        }
                    }
                }

                if (possibleMoves.items.len > 0) {
                    try moves.put(@as(u8, @intCast(i)), try possibleMoves.toOwnedSlice());
                }
            }
        }

        return moves;
    }

    // check whether move is basically valid
    fn canMove(player: Player, move: Point) bool {
        return move.player == player or move.count <= 1;
    }
};
