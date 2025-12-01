import 'dart:async';
import 'dart:ui_web';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running
}



class Player extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, KeyboardHandler{//group of animations(jump, run, etc)
  
  String character;
  Player({position, this.character = 'Ninja Frog'}) : super(position: position); //character is not required and the default if we dont receive one is Ninja Frog
  
  late final SpriteAnimation idleAnimation; //late means we dont know what it is(we'll do it later)
  late final SpriteAnimation runningAnimation;
  final double stepTime = 0.05;

  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();// x is 0 and y is 0 initially

  @override
  FutureOr<void> onLoad() {

    _loadAllAnimations();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerState();
    _updatePlayerMovement(dt);



    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    return super.onKeyEvent(event, keysPressed);
  }
  
  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation("Idle", 11);
    runningAnimation = _spriteAnimation("Run", 12);

    //linking our enum to animations. This is a list of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
    };

    //current animation
    current = PlayerState.running;
  }

  SpriteAnimation _spriteAnimation(String animationState, int amount ){
    return  SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/$character/$animationState (32x32).png'), SpriteAnimationData.sequenced(amount: amount, stepTime: stepTime, textureSize: Vector2.all(32)));
  }
  
  void _updatePlayerMovement(double dt) {
    

    velocity.x = horizontalMovement * moveSpeed;//-1 * movespeed = -movespeed, 1 * movespeed = movespeed, 0 * movespeed = 0(no movement)
    position.x += velocity.x * dt;
  }
  
  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if(velocity.x < 0 && scale.x > 0){//if velocity.x < 0 then we're moving left.
      flipHorizontallyAroundCenter();
    } else if(velocity.x > 0 && scale.x < 0){
      flipHorizontallyAroundCenter();
    }

    //check if moving, set running
    
    if(velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    current = playerState;


  }

}