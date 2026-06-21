# Modelo 3D del avatar (importado)

Aquí van los archivos del muñeco modelado en un programa externo (Blockbench).
La app los carga automáticamente si existen; si no, usa el muñeco de respaldo
generado por código (`lib/avatar3d/avatar_model.dart`).

## Qué archivos poner aquí

Exporta desde Blockbench como **OBJ** y deja en esta carpeta:

- `avatar.obj`  ← el modelo (nombre exacto)
- `avatar.mtl`  ← materiales (lo genera el export; el .obj lo referencia)
- la textura `.png` que referencie el .mtl (si pintas textura)

> El `.obj` busca el `.mtl` y la textura **por su nombre, en esta misma carpeta**.
> No los renombres por separado.

## Reglas para que encaje con flutter_cube (render por CPU, sencillo)

- **Low-poly**: pocos polígonos (objetivo: por debajo de ~3.000 caras). Nada de
  subdivisiones altas ni smooth shading pesado.
- **Ejes**: Y hacia arriba. El **frente** del muñeco mirando hacia **−Z** (en
  Blockbench, la vista "Front"). Si sale de espaldas, lo giramos en código.
- **Escala/centrado**: no crítico (al importar se reescala y lo encuadro yo),
  pero céntralo cerca del origen.
- **Color**: vale con un **material de color por pieza** (se lee el color del
  .mtl) o una **textura pintada** (mejor). Evita materiales con transparencia.
- **Sockets para ropa (más adelante)**: da a cada parte del cuerpo su **propio
  material** con nombre claro: `head`, `torso`, `armL`, `armR`, `legL`, `legR`.
  Al importar, cada material se vuelve un sub-objeto con ese nombre y podremos
  colgarle prendas. (Para la primera versión no es obligatorio.)
