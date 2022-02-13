import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/position.dart';
import '../../models/puzzle.dart';
import '../../models/tile.dart';

part 'puzzle_event.dart';
part 'puzzle_state.dart';

class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  final int _size;
  final Random? random;

  PuzzleBloc(this._size, {this.random}) : super(const PuzzleState()) {
    on<PuzzleInitialized>(_onPuzzleInitialized);
    on<TileTapped>(_onTileTapped);
    on<PuzzleAutoSolve>(_onPuzzleAutoSolve);
    on<PuzzleReset>(_onPuzzleReset);
  }

  void _onPuzzleInitialized(
    PuzzleInitialized event,
    Emitter<PuzzleState> emit,
  ) {
    final puzzle = _generatePuzzle(_size, shuffle: event.shufflePuzzle);
    emit(
      PuzzleState(
        puzzle: puzzle,
        numberOfCorrectTiles: puzzle.getNumberOfCorrectTiles(),
      ),
    );
  }

  void _onTileTapped(
    TileTapped event,
    Emitter<PuzzleState> emit,
  ) {
    final tappedTile = event.tile;
    final isPuzzleIncomplete = state.puzzleStatus == PuzzleStatus.incomplete;
    final isTileMovable = state.puzzle.isTileMovable(tappedTile);

    if (isPuzzleIncomplete && isTileMovable) {
      final mutablePuzzle = Puzzle(tiles: [...state.puzzle.tiles]);
      final puzzle = mutablePuzzle.moveTiles(tappedTile, []);
      if (puzzle.isComplete()) {
        emit(
          state.copyWith(
            puzzle: puzzle.sort(),
            puzzleStatus: PuzzleStatus.complete,
            tileMovementStatus: TileMovementStatus.moved,
            numberOfCorrectTiles: puzzle.getNumberOfCorrectTiles(),
            numberOfMoves: state.numberOfMoves + 1,
            lastTappedTile: tappedTile,
          ),
        );
      } else {
        emit(
          state.copyWith(
            puzzle: puzzle.sort(),
            tileMovementStatus: TileMovementStatus.moved,
            numberOfCorrectTiles: puzzle.getNumberOfCorrectTiles(),
            numberOfMoves: state.numberOfMoves + 1,
            lastTappedTile: tappedTile,
          ),
        );
      }
    } else {
      emit(
        state.copyWith(
          tileMovementStatus: TileMovementStatus.cannotBeMoved,
        ),
      );
    }
  }

  void _onPuzzleAutoSolve(
    PuzzleAutoSolve event,
    Emitter<PuzzleState> emit,
  ) {}

  void _onPuzzleReset(
    PuzzleReset event,
    Emitter<PuzzleState> emit,
  ) {}

  Puzzle _generatePuzzle(int size, {bool shuffle = true}) {
    final correctPositions = <Position>[];
    final currentPositions = <Position>[];
    final whitespacePosition = Position(x: size, y: size);

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (x == size && y == size) {
          correctPositions.add(whitespacePosition);
          currentPositions.add(whitespacePosition);
        } else {
          final position = Position(x: x, y: y);
          correctPositions.add(position);
          currentPositions.add(position);
        }
      }
    }

    if (shuffle) {
      currentPositions.shuffle(random);
    }

    var tiles = _getTileListFromPositions(
      size: size,
      currentPositions: currentPositions,
      correctPositions: correctPositions,
    );
    var puzzle = Puzzle(tiles: tiles);

    if (shuffle) {
      while (!puzzle.isSolvable() || puzzle.getNumberOfCorrectTiles() != 0) {
        currentPositions.shuffle(random);
        tiles = _getTileListFromPositions(
          size: size,
          currentPositions: currentPositions,
          correctPositions: correctPositions,
        );
        puzzle = Puzzle(tiles: tiles);
      }
    }

    return puzzle;
  }

  List<Tile> _getTileListFromPositions({
    required int size,
    required List<Position> currentPositions,
    required List<Position> correctPositions,
  }) {
    final whitespacePosition = Position(x: size, y: size);
    final n = size * size;
    return [
      for (int i = 0; i < n; i++)
        if (i == n - 1)
          Tile(
            value: i,
            correctPosition: whitespacePosition,
            currentPosition: currentPositions[i],
            isWhitespace: true,
            puzzleSize: size,
          )
        else
          Tile(
            value: i,
            correctPosition: correctPositions[i],
            currentPosition: currentPositions[i],
            puzzleSize: size,
          )
    ];
  }
}
