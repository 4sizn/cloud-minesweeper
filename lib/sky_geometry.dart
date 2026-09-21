import 'dart:math';

typedef Direction = ({double azimuth, double elevation});

class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x, y, z;
  double dot(Vec3 other) => x * other.x + y * other.y + z * other.z;
  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);
  Vec3 operator *(double scale) => Vec3(x * scale, y * scale, z * scale);
  Vec3 get normalized {
    final length = sqrt(dot(this));
    return this * (1 / length);
  }

  Direction get direction =>
      (azimuth: atan2(x, y), elevation: asin(normalized.z.clamp(-1, 1)));
  factory Vec3.fromDirection(double azimuth, double elevation) => Vec3(
    sin(azimuth) * cos(elevation),
    cos(azimuth) * cos(elevation),
    sin(elevation),
  );
}

/// East / magnetic north / up world axes. Camera looks through the phone's back.
class SkyView {
  const SkyView(this.right, this.up, this.forward);
  final Vec3 right, up, forward;
  factory SkyView.looking(double azimuth, double elevation) => SkyView(
    Vec3(cos(azimuth), -sin(azimuth), 0),
    Vec3(
      -sin(azimuth) * sin(elevation),
      -cos(azimuth) * sin(elevation),
      cos(elevation),
    ),
    Vec3.fromDirection(azimuth, elevation),
  );

  factory SkyView.rotation(List<double> m) => SkyView(
    Vec3(m[0], m[3], m[6]),
    Vec3(m[1], m[4], m[7]),
    Vec3(-m[2], -m[5], -m[8]),
  );

  static double focal(double width) => width / (2 * tan(pi / 6));

  Point<double>? project(
    Vec3 direction,
    double width,
    double height, {
    double zoom = 1,
  }) {
    final depth = direction.dot(forward);
    if (depth <= .08) return null;
    final f = focal(width) * zoom;
    return Point(
      width / 2 + direction.dot(right) * f / depth,
      height / 2 - direction.dot(up) * f / depth,
    );
  }

  Vec3 unproject(
    Point<double> point,
    double width,
    double height, {
    double zoom = 1,
  }) {
    final f = focal(width) * zoom;
    return (forward +
            right * ((point.x - width / 2) / f) +
            up * ((height / 2 - point.y) / f))
        .normalized;
  }
}

double wrapAngle(double angle) => (angle + pi) % (2 * pi) - pi;
