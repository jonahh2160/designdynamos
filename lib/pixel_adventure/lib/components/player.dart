import 'dart:async';
import 'dart:ui_web';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/util.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  falling,
}



class Player extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, KeyboardHandler{//group of animations(jump, run, etc)
  
  String character;
  Player({position, this.character = 'Ninja Frog'}) : super(position: position); //character is not required and the default if we dont receive one is Ninja Frog
  
  final double stepTime = 0.05;
  late final SpriteAnimation idleAnimation; //late means we dont know what it is(we'll do it later)
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;

  final double _gravity = 9.8;
  final double _jumpForce = 430;
  final double _terminalVelocity = 400; //if you are falling, there will come a time where you'll be free falling at the same speed

  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();// x is 0 and y is 0 initially
  bool isOnGround = false;
  bool hasJumped = false;
  List<CollisionBlock> collisionBlocks = [];

  @override
  FutureOr<void> onLoad() {

    _loadAllAnimations();
    debugMode = true;

    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerState();
    _updatePlayerMovement(dt);
    _checkHorizontalCollisions();//must check horizontal collision before gravity
    _applyGravity(dt);
    _checkVerticalCollisions();
    


    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);

    return super.onKeyEvent(event, keysPressed);
  }
  
  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation("Idle", 11);
    runningAnimation = _spriteAnimation("Run", 12);
    jumpingAnimation = _spriteAnimation('Jump', 1);
    fallingAnimation = _spriteAnimation('Fall', 1);

    //linking our enum to animations. This is a list of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
    };

    //current animation
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String animationState, int amount ){
    return  SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/$character/$animationState (32x32).png'), SpriteAnimationData.sequenced(amount: amount, stepTime: stepTime, textureSize: Vector2.all(32)));
  }

  
  void _updatePlayerMovement(double dt) {
    if(hasJumped && isOnGround) _playerJump(dt);

    //if(velocity.y > _gravity) isOnGround = false; optional(removes double jump)

    velocity.x = horizontalMovement * moveSpeed;//-1 * movespeed = -movespeed, 1 * movespeed = movespeed, 0 * movespeed = 0(no movement)
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;

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


    //check if falling set to falling
    if(velocity.y > 0) playerState = PlayerState.falling;


    //check if jumping set to jumping
    if(velocity.y < 0) playerState = PlayerState.jumping;

    

    current = playerState;


  }
  
  void _checkHorizontalCollisions() {
    for(final block in collisionBlocks){
      //handle collisions
      if(!block.isPlatform){
        if (checkCollision(this, block)){
          if(velocity.x > 0){//if we collide and we are going to the right
            velocity.x = 0;//stop moving
            position.x = block.x - width;//stop when collide
            break;
          }
          if(velocity.x < 0){//if we collide and we are going to the right
            velocity.x = 0;//stop moving
            position.x = block.x + block.width + width;//stop when collide front of the block
            break;
          }
        }
      }
    }
  }
  
  void _applyGravity(double dt) {
    //gravity is a velocity in the downward direction
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }
  
  void _checkVerticalCollisions() {
    for(final block in collisionBlocks){
      if(block.isPlatform){
        //handle platforms
        if(checkCollision(this, block)){
          if(velocity.y > 0){
            velocity.y = 0; //quicksand
            position.y = block.y - height;//width?
            isOnGround = true;
            break;
          }
        }
      } else{
        if(checkCollision(this, block)){
          if(velocity.y > 0){
            velocity.y = 0; //quicksand
            position.y = block.y - height;//width?
            isOnGround = true;
            break;
          }
          if(velocity.y < 0){
          velocity.y = 0;
          position.y = block.y + height;
          break;
        }
        }
        
      }
    }
  }

}