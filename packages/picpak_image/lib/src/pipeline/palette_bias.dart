class PaletteBias {
  final double black;
  final double white;
  final double red;
  final double yellow;

  const PaletteBias({
    this.black = 1.0,
    this.white = 1.0,
    this.red = 1.0,
    this.yellow = 1.0,
  });

  PaletteBias copyWith({
    double? black,
    double? white,
    double? red,
    double? yellow,
  }) {
    return PaletteBias(
      black: black ?? this.black,
      white: white ?? this.white,
      red: red ?? this.red,
      yellow: yellow ?? this.yellow,
    );
  }
}