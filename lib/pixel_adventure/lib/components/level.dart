import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/player.dart';

class Level extends World {

  final String levelName;
  final Player player;

  Level({required this.levelName, required this.player});
  
  late TiledComponent level;
  List<CollisionBlock> collisionBlocks = [];
  @override
  FutureOr<void> onLoad() async{
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));//textures are 16*16

    add(level);

    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');

    if(spawnPointsLayer != null){
      for(final spawnpoint in spawnPointsLayer.objects){
        switch(spawnpoint.class_){
          case 'Player':
            player.position =  Vector2(spawnpoint.x, spawnpoint.y);
            add(player);
            break;
          default:
        }
      }
    }

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


    return super.onLoad();
  }
}