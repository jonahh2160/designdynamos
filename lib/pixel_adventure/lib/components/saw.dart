import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Saw extends SpriteAnimationComponent with HasGameReference<PixelAdventure>{
  final bool isVertical;
  final double offsetNeg;
  final double offsetPos;
  
  Saw({this.isVertical = false, this.offsetNeg = 0, this.offsetPos = 0, size, position,}): super(position: position, size: size);

  static const double sawSpeed = 0.03; //how fast it animates
  static const moveSpeed = 50;
  static const tileSize = 16;//map tile size
  double moveDirection = 1; //means right or down
  double rangeNeg = 0;//how far saw can go negatively
  double rangePos = 0;


  @override
  FutureOr<void> onLoad() {
    priority = -1;
    add(CircleHitbox());//hitbox same size as saw. Lucky!
    debugMode = false;

    if(isVertical){
      rangeNeg = position.y - offsetNeg * tileSize;
      rangePos = position.y + offsetPos * tileSize;

    } else {
      rangeNeg = position.x - offsetNeg * tileSize;
      rangePos = position.x + offsetPos * tileSize;
    }

    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache(
        "Traps/Saw/On (38x38).png"),
         SpriteAnimationData.sequenced(amount: 8, stepTime: sawSpeed, textureSize: Vector2.all(38))
    );
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if(isVertical){
      _moveVertically(dt);
    } else {
      _moveHorizontally(dt);
    }
    super.update(dt);
  }
  
  void _moveVertically(double dt) {
    if(position.y  >= rangePos){
      moveDirection = -1;
    } else if(position.y <= rangeNeg){
      moveDirection = 1;
    }
    position.y += moveDirection * moveSpeed * dt;
  }
  
  void _moveHorizontally(double dt) {
    if(position.x  >= rangePos){
      moveDirection = -1;
    } else if(position.x <= rangeNeg){
      moveDirection = 1;
    }

    position.x += moveDirection * moveSpeed * dt;
  }
}
