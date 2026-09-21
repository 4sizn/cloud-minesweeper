import 'dart:math';

typedef CloudDraft = ({
  CloudShape shape,
  String name,
  String source,
  Difficulty difficulty,
});

enum Difficulty {
  easy('쉬움', .08),
  normal('보통', .12),
  hard('어려움', .17),
  expert('전문가', .22);

  const Difficulty(this.label, this.mineRatio);
  final String label;
  final double mineRatio;
  String get description => '${index + 1}/4 · $label';
  static Difficulty roll(Random random) =>
      values[random.nextInt(values.length)];
}

class CloudShape {
  CloudShape(this.columns, this.rows, Iterable<int> cells)
    : cells = Set.unmodifiable(cells) {
    if (columns < 1 ||
        columns > 32 ||
        rows < 1 ||
        rows > 32 ||
        this.cells.length < 2 ||
        this.cells.any((i) => i < 0 || i >= columns * rows)) {
      throw const FormatException('Invalid cloud shape');
    }
  }

  factory CloudShape.pattern(List<String> lines) =>
      CloudShape(lines.first.length, lines.length, [
        for (var y = 0; y < lines.length; y++)
          for (var x = 0; x < lines[y].length; x++)
            if (lines[y][x] == '#') y * lines.first.length + x,
      ]);

  factory CloudShape.fromJson(Map<String, dynamic> data) => CloudShape(
    data['columns'] as int,
    data['rows'] as int,
    (data['cells'] as List).cast<int>(),
  );

  final int columns;
  final int rows;
  final Set<int> cells;

  CloudShape get trimmed {
    final left = cells.map((i) => i % columns).reduce(min);
    final right = cells.map((i) => i % columns).reduce(max);
    final top = cells.map((i) => i ~/ columns).reduce(min);
    final bottom = cells.map((i) => i ~/ columns).reduce(max);
    final width = right - left + 1;
    return CloudShape(width, bottom - top + 1, [
      for (final i in cells) (i ~/ columns - top) * width + i % columns - left,
    ]);
  }

  Iterable<int> neighbors(int cell) sync* {
    final x = cell % columns, y = cell ~/ columns;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx, ny = y + dy;
        if (nx >= 0 && nx < columns && ny >= 0 && ny < rows) {
          final index = ny * columns + nx;
          if (cells.contains(index)) yield index;
        }
      }
    }
  }

  Set<int> get largestComponent {
    final remaining = cells.toSet();
    var largest = <int>{};
    while (remaining.isNotEmpty) {
      final cluster = <int>{}, queue = [remaining.first];
      while (queue.isNotEmpty) {
        final cell = queue.removeLast();
        if (!remaining.remove(cell)) continue;
        cluster.add(cell);
        queue.addAll(neighbors(cell).where(remaining.contains));
      }
      if (cluster.length > largest.length) largest = cluster;
    }
    return largest;
  }

  Map<String, dynamic> toJson() => {
    'columns': columns,
    'rows': rows,
    'cells': cells.toList()..sort(),
  };
}

final sampleClouds = <({String name, String note, CloudShape shape})>[
  (
    name: '느긋한 고래',
    note: '처음 만나기 좋은 구름',
    shape: CloudShape.pattern([
      '.........',
      '...###...',
      '..#####..',
      '.#######.',
      '#########',
      '#########',
      '.#######.',
      '..####...',
    ]),
  ),
  (
    name: '둥실둥실',
    note: '동그랗게 피어난 구름',
    shape: CloudShape.pattern([
      '...###...',
      '..#####..',
      '.#######.',
      '#########',
      '#########',
      '.#######.',
      '..#####..',
      '...###...',
    ]),
  ),
  (
    name: '긴 산책',
    note: '바람을 따라 늘어난 구름',
    shape: CloudShape.pattern([
      '..........',
      '.###......',
      '#####.....',
      '########..',
      '##########',
      '.#########',
      '...######.',
      '.....###..',
    ]),
  ),
];

enum GameStatus { ready, playing, won, lost }

class MineGame {
  MineGame({
    required this.shape,
    required this.seed,
    required this.name,
    String? id,
    this.source = 'sample',
    this.difficulty = Difficulty.normal,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}-$seed';

  final String id;
  final String name;
  final String source;
  final Difficulty difficulty;
  final CloudShape shape;
  final int seed;
  final Set<int> mines = {}, opened = {}, flagged = {};
  GameStatus status = GameStatus.ready;
  int? exploded;
  int? firstCell;
  int get mineCount => (shape.cells.length * difficulty.mineRatio)
      .floor()
      .clamp(1, shape.cells.length - 1);
  int get safeCount => shape.cells.length - mineCount;
  int adjacent(int cell) => shape.neighbors(cell).where(mines.contains).length;
  bool get finished => status == GameStatus.won || status == GameStatus.lost;

  void flag(int cell) {
    if (finished || !shape.cells.contains(cell) || opened.contains(cell)) {
      return;
    }
    if (!flagged.remove(cell)) flagged.add(cell);
  }

  void open(int cell) {
    if (finished || !shape.cells.contains(cell) || flagged.contains(cell)) {
      return;
    }
    if (status == GameStatus.ready) {
      final excluded = {cell, ...shape.neighbors(cell)};
      var candidates = shape.cells.where((i) => !excluded.contains(i)).toList()
        ..sort();
      // Tiny custom boards may not have space for a safe neighborhood.
      if (candidates.length < mineCount) {
        candidates = shape.cells.where((i) => i != cell).toList()..sort();
      }
      candidates.shuffle(Random(seed));
      mines.addAll(candidates.take(mineCount));
      firstCell = cell;
      status = GameStatus.playing;
    }
    if (opened.contains(cell)) {
      if (shape.neighbors(cell).where(flagged.contains).length !=
          adjacent(cell)) {
        return;
      }
      for (final neighbor in shape.neighbors(cell)) {
        if (!opened.contains(neighbor) && !flagged.contains(neighbor)) {
          _reveal(neighbor);
        }
        if (finished) break;
      }
    } else {
      _reveal(cell);
    }
    if (status != GameStatus.lost && opened.length == safeCount) {
      status = GameStatus.won;
    }
  }

  void _reveal(int cell) {
    if (mines.contains(cell)) {
      exploded = cell;
      status = GameStatus.lost;
      return;
    }
    final queue = [cell];
    while (queue.isNotEmpty) {
      final next = queue.removeLast();
      if (flagged.contains(next) || !opened.add(next)) continue;
      if (adjacent(next) == 0) {
        queue.addAll(
          shape
              .neighbors(next)
              .where((i) => !opened.contains(i) && !mines.contains(i)),
        );
      }
    }
  }
}

class CloudPiece {
  CloudPiece({
    required this.id,
    required this.name,
    required this.shape,
    required this.collectedAt,
    required this.seconds,
    required this.source,
    this.azimuth = 0,
    this.elevation = .35,
    this.distance = 1,
    this.difficulty = Difficulty.normal,
    this.placed = false,
  });

  // Relative scene distance, not GPS metres. Existing collections use 1.
  static const minDistance = .5;
  static const maxDistance = 6.0;

  factory CloudPiece.fromWin(MineGame game, int seconds) {
    if (game.status != GameStatus.won) {
      throw StateError('Only won clouds can be collected');
    }
    return CloudPiece(
      id: game.id,
      name: game.name,
      shape: game.shape,
      collectedAt: DateTime.now(),
      seconds: seconds,
      source: game.source,
      difficulty: game.difficulty,
    );
  }

  factory CloudPiece.fromJson(Map<String, dynamic> json) {
    final az = (json['azimuth'] as num).toDouble();
    final el = (json['elevation'] as num).toDouble();
    final distance = (json['distance'] as num? ?? 1).toDouble();
    final seconds = json['seconds'] as int;
    if (!az.isFinite ||
        !el.isFinite ||
        el.abs() > pi / 2 ||
        !distance.isFinite ||
        distance < minDistance ||
        distance > maxDistance ||
        seconds < 0 ||
        (json['name'] as String).length > 100 ||
        (json['id'] as String).isEmpty) {
      throw const FormatException('Invalid cloud record');
    }
    return CloudPiece(
      id: json['id'] as String,
      name: json['name'] as String,
      shape: CloudShape.fromJson(json['shape'] as Map<String, dynamic>),
      collectedAt: DateTime.parse(json['collectedAt'] as String),
      seconds: seconds,
      source: json['source'] as String,
      difficulty: Difficulty.values.byName(
        json['difficulty'] as String? ?? Difficulty.normal.name,
      ),
      azimuth: az,
      elevation: el,
      distance: distance,
      placed: json['placed'] as bool,
    );
  }

  final String id;
  String name;
  final CloudShape shape;
  final DateTime collectedAt;
  final int seconds;
  final String source;
  final Difficulty difficulty;
  double azimuth;
  double elevation;
  double distance;
  bool placed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shape': shape.toJson(),
    'collectedAt': collectedAt.toIso8601String(),
    'seconds': seconds,
    'source': source,
    'difficulty': difficulty.name,
    'azimuth': azimuth,
    'elevation': elevation,
    'distance': distance,
    'placed': placed,
  };
}

String clockLabel(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
