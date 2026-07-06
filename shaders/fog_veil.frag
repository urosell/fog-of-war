#version 460 core

// Velo de niebla con agujeros metaball, en una sola pasada.
//
// La capa de niebla hornea (rara vez) una máscara: la mancha difuminada de
// las celdas descubiertas, blanca sobre transparente. Este shader se dibuja
// a pantalla completa cada frame y, por píxel: muestrea esa máscara, aplica
// el umbral que convierte el difuminado en un borde nítido (a resolución de
// pantalla, por eso reescalar la máscara no lo ablanda) y pinta el velo con
// el agujero ya recortado. Así no hace falta ningún saveLayer ni modo de
// mezcla raro por frame (los gotchas de Impeller con umbral+dstOut
// desaparecen: aquí se emite directamente el color final premultiplicado).

#include <flutter/runtime_effect.glsl>

precision highp float;

// Transformación afín pantalla→UV de la máscara: uv = origen + perX·x + perY·y.
// Se calcula en CPU con precisión doble; aquí solo llegan valores pequeños.
uniform vec2 uUvPerX;
uniform vec2 uUvPerY;
uniform vec2 uUvOrigin;

// Color del velo (no premultiplicado).
uniform vec4 uFogColor;

// Umbral metaball: alpha_out = slope·(alpha − cut). uCutInner es el umbral
// erosionado que da el grosor del ribete.
uniform float uSlope;
uniform float uCutEdge;
uniform float uCutInner;

// Color del ribete en el límite descubierto/niebla. Alpha 0 = sin ribete.
uniform vec4 uBorderColor;

// Tamaño de la máscara en texels.
uniform vec2 uMaskSize;

// Máscara horneada (mancha difuminada, sin umbralizar).
uniform sampler2D uMask;

out vec4 fragColor;

// Muestreo bilineal manual: el sampler puede venir con filtro nearest (pasa
// con Impeller) y el umbral convertiría los texels en escalones visibles.
// Cuatro muestras en centros de texel (exactas con nearest) y mezcla.
float sampleMask(vec2 uv) {
  vec2 st = uv * uMaskSize - 0.5;
  vec2 base = floor(st);
  vec2 f = st - base;
  // Centros de texel, sin salirse del borde (clamp a media celda del límite).
  vec2 lo = vec2(0.5);
  vec2 hi = uMaskSize - 0.5;
  vec2 p00 = clamp(base + vec2(0.5, 0.5), lo, hi) / uMaskSize;
  vec2 p10 = clamp(base + vec2(1.5, 0.5), lo, hi) / uMaskSize;
  vec2 p01 = clamp(base + vec2(0.5, 1.5), lo, hi) / uMaskSize;
  vec2 p11 = clamp(base + vec2(1.5, 1.5), lo, hi) / uMaskSize;
  float a00 = texture(uMask, p00).a;
  float a10 = texture(uMask, p10).a;
  float a01 = texture(uMask, p01).a;
  float a11 = texture(uMask, p11).a;
  return mix(mix(a00, a10, f.x), mix(a01, a11, f.x), f.y);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 uv = uUvOrigin + uUvPerX * p.x + uUvPerY * p.y;

  // Fuera de la máscara no hay nada descubierto: cobertura 0 (velo pleno).
  vec2 inb = step(vec2(0.0), uv) * step(uv, vec2(1.0));
  float c = sampleMask(clamp(uv, 0.0, 1.0)) * inb.x * inb.y;

  // Umbral: agujero (borde exterior) y su versión erosionada (para el ribete).
  float edge = clamp(uSlope * (c - uCutEdge), 0.0, 1.0);
  float inner = clamp(uSlope * (c - uCutInner), 0.0, 1.0);

  // Velo con el agujero restado.
  float veilA = uFogColor.a * (1.0 - edge);

  // Ribete: anillo entre ambos umbrales, compuesto encima (srcOver).
  float ring = (edge - inner) * uBorderColor.a;
  float outA = ring + veilA * (1.0 - ring);
  vec3 outRgb = uBorderColor.rgb * ring + uFogColor.rgb * veilA * (1.0 - ring);

  fragColor = vec4(outRgb, outA);
}
