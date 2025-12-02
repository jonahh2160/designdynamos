import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_adventure/components/background_tile.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Level extends World with HasGameReference<PixelAdventure>{

  final String levelName;
  final Player player;

  Level({required this.levelName, required this.player});
  
  late TiledComponent level;
  List<CollisionBlock> collisionBlocks = [];
  @override
  FutureOr<void> onLoad() async{
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));//textures are 16*16

    add(level);

    _scrollingBackground();
    _spawningObjects();
    _addCollisions();

    return super.onLoad();
  }
  
  void _scrollingBackground() {
    final backgroundLayer = level.tileMap.getLayer('Background');
    const tileSize = 64;

    final numTilesY = (game.size.y / tileSize).floor();
    final numTilesX = (game.size.x / tileSize).floor();

    if(backgroundLayer != null){
      final backgroundColor = backgroundLayer.properties.getValue('BackgroundColor');

      for(double y =0; y < game.size.y / numTilesY; y++){
        for(double x = 0; x < numTilesX; x++){
          final backgroundTile = BackgroundTile(color:backgroundColor ?? 'Gray', position: Vector2(x * tileSize,y * tileSize - tileSize));//?? is the same as backgroundColor != null ? backgroundColor : 'Gray'
          add(backgroundTile);
        }
      }
    }
  }
  
  void _spawningObjects() {
    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');

    if(spawnPointsLayer != null){
      for(final spawnpoint in spawnPointsLayer.objects){
        switch(spawnpoint.class_){
          case 'Player':
            player.position =  Vector2(spawnpoint.x, spawnpoint.y);
            add(player);
            break;
          case 'Fruit':
            final fruit = Fruit(
              fruit: spawnpoint.name,
              position: Vector2(spawnpoint.x, spawnpoint.y),
              size: Vector2(spawnpoint.width, spawnpoint.height),
            );
            add(fruit);
            break;
          case 'Saw':
            final isVertical = spawnpoint.properties.getValue('isVertical');
            final offsetNeg = spawnpoint.properties.getValue('offsetNeg');
            final offsetPos= spawnpoint.properties.getValue('offsetPos');

            final saw = Saw(
              isVertical: isVertical,
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              position: Vector2(spawnpoint.x, spawnpoint.y),
              size: Vector2(spawnpoint.width, spawnpoint.height),
            );
            add(saw);
            break;

          default:
        }
      }
    }
  }
  
  void _addCollisions() {
    final collisionLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');

    if(collisionLayer != null){
      for(final collision in collisionLayer.objects){
        switch (collision.class_) {
          case 'Platform':
            final platform = CollisionBlock(position: Vector2(collision.x, collision.y), size: Vector2(collision.width, collision.height), isPlatform: true,);
            collisionBlocks.add(platform);

            add(platform);
            break;
          default:
            final block = CollisionBlock(position: Vector2(collision.x, collision.y), size: Vector2(collision.width, collision.height),);
            collisionBlocks.add(block);

            add(block);
            break;
        }
      }
    }

    player.collisionBlocks = collisionBlocks;//passing collision blocks to players
  }
}