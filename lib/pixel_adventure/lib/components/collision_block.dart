import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent{//because platforms have x and y and width and height
  bool isPlatform;
  CollisionBlock({position, size, this.isPlatform = false,}) : super(position: position, size: size) {debugMode = true;}//passing position and size to super because its a position component



}