import 'dart:async';

import 'package:flame/components.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class BackgroundTile extends SpriteComponent with HasGameReference<PixelAdventure>{//extends SpriteComponent because allows us to pass image and it extends position componenet
  final String color;
  BackgroundTile({this.color = 'Gray', position}) : super(position: position);//default color is gray


  final double scrollSpeed = 0.4;

  @override
  FutureOr<void> onLoad() {
    priority = -1;
    size = Vector2.all(64.6);//adding the .6 allows the lines to blend nicely
    sprite = Sprite(game.images.fromCache('Background/$color.png'));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    position.y += scrollSpeed;
    double tileSize = 64;

    int scrollHeight = (game.size.y/tileSize).floor();

    if(position.y > scrollHeight * tileSize) position.y = -tileSize;//we start at negative tilesize(above screen) and once its time to repeat it starts from -63 aswell
    super.update(dt);
  }
}