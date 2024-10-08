const std = @import("std");
const engine = @import("zbg.zig");
const testing = std.testing;
const Board = engine.Board;
const GameState = engine.GameState;
const Player = engine.Player;
const RulesEngine = engine.RulesEngine;

test "Board.movePiece" {
    var board = Board.init();
    const players = [2]Player{
        Player.init("Player 1", 0),
        Player.init("Player 2", 1),
    };
    board.dressBoard(&players);

    // Test moving a piece from point 1 to point 2
    try testing.expect(board.points[1].count == 2);
    try testing.expect(board.points[2].count == 0);
    board.movePiece(1, 2);
    try testing.expect(board.points[1].count == 1);
    try testing.expect(board.points[2].count == 1);

    // Test moving a piece from point 24 to point 23
    try testing.expect(board.points[24].count == 2);
    try testing.expect(board.points[23].count == 0);
    board.movePiece(24, 23);
    try testing.expect(board.points[24].count == 1);
    try testing.expect(board.points[23].count == 1);
}

test "GameState.rollDice" {
    var gameState = GameState.init("Player 1", "Player 2");

    // Test rolling dice multiple times
    for (0..100) |_| {
        gameState.rollDice();
        try testing.expect(gameState.dice[0] >= 1 and gameState.dice[0] <= 6);
        try testing.expect(gameState.dice[1] >= 1 and gameState.dice[1] <= 6);
    }
}

test "RulesEngine.isValidMove" {
    var gameState = GameState.init("Player 1", "Player 2");
    const allocator = std.testing.allocator;

    const validMoves = try RulesEngine.getAllValidMoves(&gameState, allocator);
    defer validMoves.deinit();

    // Test a valid move
    const fromPoint = gameState.board.points[1];
    const toPoint = gameState.board.points[2];
    try testing.expect(RulesEngine.isValidMove(fromPoint, toPoint, validMoves));

    // Test an invalid move
    const invalidToPoint = gameState.board.points[20];
    try testing.expect(!RulesEngine.isValidMove(fromPoint, invalidToPoint, validMoves));
}

test "RulesEngine.getAllValidMoves" {
    var gameState = GameState.init("Player 1", "Player 2");
    const allocator = std.testing.allocator;

    gameState.dice = .{ 3, 4 };
    const validMoves = try RulesEngine.getAllValidMoves(&gameState, allocator);
    defer validMoves.deinit();

    // Check that there are valid moves for the starting positions
    try testing.expect(validMoves.contains(gameState.board.points[1]));
    try testing.expect(validMoves.contains(gameState.board.points[12]));
    try testing.expect(validMoves.contains(gameState.board.points[17]));
    try testing.expect(validMoves.contains(gameState.board.points[19]));

    // Check that there are no valid moves for empty points or opponent's points
    try testing.expect(!validMoves.contains(gameState.board.points[6]));
    try testing.expect(!validMoves.contains(gameState.board.points[7]));
}
