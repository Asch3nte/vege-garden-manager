#version 460 core
// Equirectangular earth texture wrapped on an orthographic globe.
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uRadius;
uniform float uLon0;
uniform float uLat0;
uniform sampler2D uTex;

out vec4 fragColor;

const float PI = 3.14159265359;

void main() {
  vec2 p = (FlutterFragCoord().xy - uSize * 0.5) / uRadius;
  float r2 = dot(p, p);
  if (r2 > 1.0) {
    fragColor = vec4(0.0);
    return;
  }
  float x = p.x;
  float y = -p.y;
  float z = sqrt(1.0 - r2);
  float cl = cos(uLat0);
  float sl = sin(uLat0);
  // Inverse orthographic projection centred on (uLat0, uLon0).
  float lat = asin(clamp(y * cl + z * sl, -1.0, 1.0));
  float lon = uLon0 + atan(x, z * cl - y * sl);
  vec2 uv = vec2(fract(lon / (2.0 * PI) + 0.5), 0.5 - lat / PI);
  vec3 c = texture(uTex, uv).rgb;
  float lumiere = 0.55 + 0.45 * z;
  float bord = clamp((1.0 - sqrt(r2)) * uRadius, 0.0, 1.0);
  fragColor = vec4(c * lumiere * bord, bord);
}
