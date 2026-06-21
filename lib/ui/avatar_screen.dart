// Pantalla del personaje 3D del jugador.
//
// Muestra el muñeco en una escena 3D que se puede girar arrastrando y
// acercar/alejar con dos dedos (lo trae el widget Cube). Si existe un modelo
// importado en assets/avatar/avatar.obj (hecho en Blockbench), lo carga; si no,
// cae al muñeco generado por código (avatar_model.dart). Es la base sobre la que
// luego se le pondrá ropa desbloqueada con las medallas.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_cube/flutter_cube.dart' as cube;

import '../avatar3d/avatar_model.dart';
import '../l10n/l10n_ext.dart';

// Modelo importado (opcional). Si no está en el bundle, se usa el de código.
const String _kModelAsset = 'assets/avatar/avatar.obj';
// Al importar, flutter_cube reescala el modelo a ~0.5 de alto; lo agrandamos
// para encuadrarlo como el muñeco por código. Se afinará con el modelo real.
const double _kModelScale = 4.2;

class AvatarScreen extends StatelessWidget {
  const AvatarScreen({super.key});

  void _onSceneCreated(cube.Scene scene) {
    // Cámara: vista 3/4 (algo a la izquierda y desde arriba) para que se note el
    // 3D de entrada, alejada lo justo para que quepa entero al rotar.
    scene.camera.position.setValues(-1.1, 0.4, -4.2);
    scene.camera.target.setValues(0, 0, 0);
    scene.camera.fov = 45;
    // Luz desde arriba-izquierda, hacia la cámara, con bastante ambiente para
    // que el muñeco se lea bien por todos lados. (El tipo Light no está
    // exportado por el paquete, así que ajustamos la luz que ya trae la escena.)
    scene.light.position.setValues(-3, 5, -4);
    scene.light.setColor(null, 0.5, 0.7, 0.0);

    _addModel(scene);
  }

  // Intenta cargar el modelo importado; si no existe, usa el muñeco por código.
  Future<void> _addModel(cube.Scene scene) async {
    var usarImportado = false;
    try {
      await rootBundle.load(_kModelAsset); // lanza si no está en el bundle
      usarImportado = true;
    } catch (_) {
      usarImportado = false;
    }

    if (usarImportado) {
      scene.world.add(cube.Object(
        fileName: _kModelAsset,
        lighting: true,
        backfaceCulling: true,
        scale: cube.Vector3(_kModelScale, _kModelScale, _kModelScale),
      ));
    } else {
      scene.world.add(buildMannequin());
    }
    scene.updateTexture();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(l.avatarTitle),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF2A3450), Color(0xFF0E1117)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: cube.Cube(onSceneCreated: _onSceneCreated),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.threed_rotation,
                        color: Colors.white54, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l.avatarRotateHint,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
