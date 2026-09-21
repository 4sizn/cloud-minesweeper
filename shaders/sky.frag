#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uFocal;
uniform vec3 uRight;
uniform vec3 uUp;
uniform vec3 uForward;
uniform sampler2D uSky;
out vec4 fragColor;

void main() {
  vec2 p = FlutterFragCoord().xy - uSize * 0.5;
  vec3 ray = normalize(uForward + uRight * p.x / uFocal - uUp * p.y / uFocal);
  float longitude = atan(ray.x, ray.y) / 6.28318530718 + 0.5;
  // Mirror the existing sky photograph around the dome for a continuous wrap.
  float u = 1.0 - abs(fract(longitude + 0.125) * 2.0 - 1.0);
  float v = clamp(0.66 - asin(clamp(ray.z, -1.0, 1.0)) * 2.0 / 3.14159265359, 0.0, 1.0);
  vec3 sky = texture(uSky, vec2(u, v)).rgb;
  // Fade the texture at the poles, where longitude has no unique direction.
  float pole = smoothstep(0.92, 1.0, abs(ray.z));
  sky = mix(sky, vec3(0.69, 0.83, 0.93), pole);
  fragColor = vec4(sky, 1.0);
}
