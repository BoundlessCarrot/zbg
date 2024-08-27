const std = @import("std");

const Board = struct {
    points: [26]Point,
    bar: [2]u8,
    bearOff: [2]u8,

    const Self = @This();

    pub fn init() Board {
        return Board{ .points = [_]Point{Point{.player = undefined, .count = 0}} ** 26, .bar = [2]u8{ 0, 0 }, .bearOff = [2]u8{ 0, 0 } };
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
    // NOTE: Would it be better to do all rules that say you *can't* move or just generate all the valid moves?
    pub fn isValidMove(gameState: *GameState, from: u8, to: u8) bool {
        const from_point = gameState.board.points[from];
        const to_point = gameState.board.points[to];
        // if (from_point.player != gameState.currentPlayer) return false;
        // if (to_point.player != gameState.currentPlayer && to.count > 1) return false;
        // if (from + gameState.dice[0] != to && from + gameState.dice[1] != to) return false;
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

    pub fn getAllValidMoves(gameState: *GameState, allocator: std.mem.Allocator) []Point {
        var moves = std.AutoHashMap(Point, []Point).init(allocator);
        defer moves.deinit();

        const internalGameBoard: [26]Point = if (std.mem.eql(gameState.currentPlayer.name, "Player 1")) gameState.board.points else std.mem.reverse(Point, gameState.board.points);
        
        for (internalGameBoard, 0..) |point, i| {
            if (point.player == gameState.currentPlayer) {
                const jump_0 = gameState.board.points[i + gameState.dice[0]];
                const jump_1 = gameState.board.points[i + gameState.dice[1]];

                if (canMove(gameState.currentPlayer, jump_0)) moves.put(point, jump_0);
                if (canMove(gameState.currentPlayer, jump_1)) moves.put(point, jump_1);

                const jump_2 = if (jump_0.player == gameState.currentPlayer) gameState.board.points[i + gameState.dice[0] + gameState.dice[0]] else undefined;
                const jump_3 = if (jump_1.player == gameState.currentPlayer) gameState.board.points[i + gameState.dice[1] + gameState.dice[0]] else undefined;
            }
        }
        return moves;
    }

    fn canMove(player: Player, move: Point) bool {
        return move.player == player or move.count <= 1;
    }
};
