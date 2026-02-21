enum CellState { given, empty, filled, error }

class SudokuCell {
  int value; // 0 means empty
  int solution; // correct value
  CellState state;
  Set<int> notes; // pencil marks
  bool isSelected;
  bool isHighlighted;
  bool isConflict;
  bool isSameValue;
  bool isCelebrating;
  final int row;
  final int col;

  SudokuCell({
    this.value = 0,
    this.solution = 0,
    this.state = CellState.empty,
    Set<int>? notes,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isConflict = false,
    this.isSameValue = false,
    this.isCelebrating = false,
    required this.row,
    required this.col,
  }) : notes = notes ?? {};

  bool get isEmpty => value == 0;
  bool get isGiven => state == CellState.given;
  bool get hasNotes => notes.isNotEmpty;
  bool get isCorrect => value == solution;

  int get box => (row ~/ 3) * 3 + (col ~/ 3);

  SudokuCell copyWith({
    int? value,
    int? solution,
    CellState? state,
    Set<int>? notes,
    bool? isSelected,
    bool? isHighlighted,
    bool? isConflict,
    bool? isSameValue,
    bool? isCelebrating,
  }) {
    return SudokuCell(
      value: value ?? this.value,
      solution: solution ?? this.solution,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isConflict: isConflict ?? this.isConflict,
      isSameValue: isSameValue ?? this.isSameValue,
      isCelebrating: isCelebrating ?? this.isCelebrating,
      row: row,
      col: col,
    );
  }
}

class SudokuBoard {
  final List<List<SudokuCell>> cells;

  SudokuBoard({List<List<SudokuCell>>? cells})
      : cells = cells ??
            List.generate(
              9,
              (row) => List.generate(
                9,
                (col) => SudokuCell(row: row, col: col),
              ),
            );

  SudokuCell getCell(int row, int col) => cells[row][col];

  void setCell(int row, int col, SudokuCell cell) {
    cells[row][col] = cell;
  }

  SudokuBoard deepCopy() {
    return SudokuBoard(
      cells: List.generate(
        9,
        (row) => List.generate(
          9,
          (col) => cells[row][col].copyWith(),
        ),
      ),
    );
  }

  bool isBoardComplete() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (cells[row][col].isEmpty || !cells[row][col].isCorrect) {
          return false;
        }
      }
    }
    return true;
  }

  int get filledCount {
    int count = 0;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (!cells[row][col].isEmpty) count++;
      }
    }
    return count;
  }

  int get emptyCount => 81 - filledCount;
}
