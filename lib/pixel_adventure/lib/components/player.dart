import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  hit,
  appearing,
  disappearing,
}



class Player extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, KeyboardHandler, CollisionCallbacks{//group of animations(jump, run, etc)
  
  String character;
  Player({position, this.character = 'Ninja Frog'}) : super(position: position); //character is not required and the default if we dont receive one is Ninja Frog
  
  final double stepTime = 0.05;
  late final SpriteAnimation idleAnimation; //late means we dont know what it is(we'll do it later)
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;

  final double _gravity = 9.8;
  final double _jumpForce = 260;
  final double _terminalVelocity = 300; //if you are falling, there will come a time where you'll be free falling at the same speed

  double horizontalMovement = 0;
  double moveSpeed = 100;

  Vector2 startingPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();//x is 0 and y is 0 initially
  bool isOnGround = false;
  bool hasJumped = false;
  bool gotHit = false;
  bool reachedCheckpoint = false;

  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10, 
    offsetY: 4, 
    width: 14, 
    height: 28);

  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  @override
  FutureOr<void> onLoad() {

    _loadAllAnimations();
    //debugMode = true;

    startingPosition = Vector2(position.x, position.y);

    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));

    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;

    while(accumulatedTime >= fixedDeltaTime){
      if(!gotHit && !reachedCheckpoint){
      _updatePlayerState();
      _updatePlayerMovement(fixedDeltaTime);
      _checkHorizontalCollisions();//must check horizontal collision before gravity
      _applyGravity(fixedDeltaTime);
      _checkVerticalCollisions();
      }

      accumulatedTime -= fixedDeltaTime;
    }

    

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

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if(!reachedCheckpoint){
      if(other is Fruit) other.collidedWithPlayer();
      if(other is Saw) _respawn();
      if(other is Checkpoint && !reachedCheckpoint) _reachedCheckpoint();

    }
    super.onCollisionStart(intersectionPoints, other);
  }
  
  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation("Idle", 11);
    runningAnimation = _spriteAnimation("Run", 12);
    jumpingAnimation = _spriteAnimation('Jump', 1);
    fallingAnimation = _spriteAnimation('Fall', 1);
    hitAnimation = _spriteAnimation('Hit', 7)..loop=false;
    appearingAnimation = _specialSpriteAnimation('Appearing', 7);
    disappearingAnimation = _specialSpriteAnimation('Desappearing', 7);


    //linking our enum to animations. This is a list of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
      
    };

    //current animation
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String animationState, int amount ){
    return  SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/$character/$animationState (32x32).png'), SpriteAnimationData.sequenced(amount: amount, stepTime: stepTime, textureSize: Vector2.all(32),));
  }

  SpriteAnimation _specialSpriteAnimation(String animationState, int amount ){
    return  SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/$animationState (96x96).png'), SpriteAnimationData.sequenced(amount: amount, stepTime: stepTime, textureSize: Vector2.all(96), loop: false));
  }

  
  void _updatePlayerMovement(double dt) {
    if(hasJumped && isOnGround) _playerJump(dt);

    //if(velocity.y > _gravity) isOnGround = false; optional(removes double jump)

    velocity.x = horizontalMovement * moveSpeed;//-1 * movespeed = -movespeed, 1 * movespeed = movespeed, 0 * movespeed = 0(no movement)
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    if(game.playSounds){
      FlameAudio.play('jump.wav', volume: game.soundVolume);
    }
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
            position.x = block.x - hitbox.offsetX - hitbox.width;//stop when collide
            break;
          }
          if(velocity.x < 0){//if we collide and we are going to the right
            velocity.x = 0;//stop moving
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;//stop when collide front of the block
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
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else{
        if(checkCollision(this, block)){
          if(velocity.y > 0){
            velocity.y = 0; //quicksand
            position.y = block.y - hitbox.height - hitbox.offsetY;//width?
            isOnGround = true;
            break;
          }
          if(velocity.y < 0){
          velocity.y = 0;
          position.y = block.y + block.height - hitbox.offsetY;
        }
        }
        
      }
    }
  }

  void _respawn() async{

    if(game.playSounds){
      FlameAudio.play('hit.wav', volume: game.soundVolume);
    }
    const canMoveDuration = Duration(milliseconds: 400);
    gotHit = true;
    current = PlayerState.hit;
    
    await animationTicker?.completed;
    animationTicker?.reset();

    scale.x = 1;
    position = startingPosition - Vector2.all(32);
    current = PlayerState.appearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    velocity = Vector2.zero();
    position = startingPosition;
    _updatePlayerState();
    Future.delayed(canMoveDuration, () => gotHit = false);
  }
  
  void _reachedCheckpoint() async{
    reachedCheckpoint = true;

    if(game.playSounds){
      FlameAudio.play('disappear.wav', volume: game.soundVolume);
    }

    if(scale.x > 0){
      position = position - Vector2.all(32);
    } else if(scale.x < 0){
      position = position + Vector2(32, -32);
    }

    current = PlayerState.disappearing;
    
    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;
    position = Vector2.all(-640); //move off screen

    const waitToChangeDuration = Duration(seconds: 3);
    Future.delayed(waitToChangeDuration, () => game.loadNextLevel());
 
  }

}