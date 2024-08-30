const std = @import("std");

const Board = struct {
    points: [26]Point,
    bar: [2]u8,
    bearOff: [2]u8,

    const Self = @This();

    pub fn init() Board {
        return Board{ .points = [_]Point{Point{ .player = undefined, .count = 0 }} ** 26, .bar = [2]u8{ 0, 0 }, .bearOff = [2]u8{ 0, 0 } };
    }

    pub fn movePiece(self: Self, from: u8, to: u8) void {
        self.points[from].count -= 1;
        self.points[to].count += 1;
    }
};

const Point = struct {
    player: u8,
    count: u8,
};

const Player = struct {
    name: []const u8,
    color: usize,
    score: usize,

    const Self = @This();

    pub fn init(name: []const u8, color: usize) Player {
        return Player{ .name = name, .color = color, .score = 0 };
    }
};

const GameState = struct {
    board: Board,
    players: [2]Player,
    currentPlayer: Player,
    dice: [2]u8,

    const Self = @This();

    pub fn init() GameState {
        return GameState{ .board = Board.init(), .players = [2]Player{ Player.init("Player 1", 0), Player.init("Player 2", 1) }, .currentPlayer = 0, .dice = [2]u8{ undefined, undefined } };
    }
};

const RulesEngine = struct {
    pub fn isValidMove(from: Point, to: Point, validMovesHash: std.AutoHashMap(Point, []Point)) bool {
        if (validMovesHash.contains(from)) {
            const moveList = validMovesHash.get(from);
            if (std.mem.containsAtLeast(Point, moveList, 1, to)) {
                return true;
            }
        }

        return false;
    }

    pub fn isGameOver(gameState: *GameState) bool {
        return (gameState.board.points[25].count == 15 or gameState.board.points[0].count == 15);
    }

    pub fn getWinner(gameState: *GameState) Player {
        var player: Player = undefined;
        if (gameState.board.points[0].count == 15) {
            player = gameState.players[0];
        } else if (gameState.board.points[24].count == 15) {
            player = gameState.players[1];
        }
        return player;
    }

    pub fn getAllValidMoves(gameState: *GameState, allocator: std.mem.Allocator) std.AutoHashmap(Point, []Point) {
        var moves = std.AutoHashMap(Point, [4]Point).init(allocator);
        defer moves.deinit();

        const internalGameBoard: [26]Point = if (std.mem.eql(gameState.currentPlayer.name, "Player 1")) gameState.board.points else std.mem.reverse(Point, gameState.board.points);

        for (internalGameBoard, 0..) |point, i| {
            if (point.player == gameState.currentPlayer) {
                // NOTE: Doesn't include doubles
                var pointList = allocator.alloc(Point, 4);
                defer allocator.free(pointList);

                const jump_0 = gameState.board.points[i + gameState.dice[0]];
                const jump_1 = gameState.board.points[i + gameState.dice[1]];

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

    fn canMove(player: Player, move: Point) bool {
        return move.player == player or move.count <= 1;
    }
};
