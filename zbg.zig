const std = @import("std");

pub const Board = struct {
    points: [26]Point,
    bar: [2]u8,
    bearOff: [2]u8,

    const Self = @This();

    pub fn init() Board {
        const points = [_]Point{Point{ .player = undefined, .count = 0 }} ** 26;
        return Board{ .points = points, .bar = [2]u8{ 0, 0 }, .bearOff = [2]u8{ 0, 0 } };
    }

    // TODO: Needs test case(s)
    pub fn movePiece(self: *Self, from: u8, to: u8) void {
        self.points[from].count -= 1;
        self.points[to].count += 1;
    }

    // Set the bpard for various game types. Will be expanded later
    pub fn dressBoard(self: *Self, players: [2]Player) void {
        self.points[1] = Point{ .player = players[0], .count = 2 };
        self.points[12] = Point{ .player = players[0], .count = 5 };
        self.points[17] = Point{ .player = players[0], .count = 3 };
        self.points[19] = Point{ .player = players[0], .count = 5 };

        self.points[6] = Point{ .player = players[1], .count = 5 };
        self.points[8] = Point{ .player = players[1], .count = 3 };
        self.points[13] = Point{ .player = players[1], .count = 5 };
        self.points[24] = Point{ .player = players[1], .count = 2 };
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
        return (gameState.board.points[25].count == 15 or gameState.board.points[0].count == 15);
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
    pub fn getAllValidMoves(gameState: *GameState, allocator: std.mem.Allocator) std.AutoHashMap(Point, []Point) {
        var moves = std.AutoHashMap(Point, [4]Point).init(allocator);
        defer moves.deinit();

        const internalGameBoard: [26]Point = if (std.mem.eql(gameState.currentPlayer.name, "Player 1")) gameState.board.points else std.mem.reverse(Point, gameState.board.points);

        for (internalGameBoard, 0..) |point, i| {
            if (point.player == gameState.currentPlayer) {
                // NOTE: Doesn't include doubles
                var pointList = allocator.alloc(Point, 4);
                defer allocator.free(pointList);

                const jump_0 = internalGameBoard[i + gameState.dice[0]];
                const jump_1 = internalGameBoard[i + gameState.dice[1]];

                const jump_0_validator: bool = canMove(gameState.currentPlayer, jump_0);
                const jump_1_validator: bool = canMove(gameState.currentPlayer, jump_1);

                if (jump_0_validator) {
                    pointList[0] = jump_0;
                    const jump_2 = internalGameBoard[i + gameState.dice[0] + gameState.dice[1]];
                    if (canMove(gameState.currentPlayer, jump_2)) pointList[2] = jump_2;
                }
                if (jump_1_validator) {
                    pointList[1] = jump_1;
                    const jump_3 = internalGameBoard[i + gameState.dice[1] + gameState.dice[0]];
                    if (canMove(gameState.currentPlayer, jump_3)) pointList[3] = jump_3;
                }

                moves.put(point, pointList);
            }
        }
        return moves;
    }

    // check whether move is basically valid
    fn canMove(player: Player, move: Point) bool {
        return move.player == player or move.count <= 1;
    }
};
