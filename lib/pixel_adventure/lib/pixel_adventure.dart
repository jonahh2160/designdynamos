import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:pixel_adventure/components/JumpButton.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/level.dart';

class PixelAdventure extends FlameGame with HasKeyboardHandlerComponents, DragCallbacks, TapCallbacks, HasCollisionDetection{

  @override
  Color backgroundColor() => const Color(0xFF211F30);//0xFF means no transparency
  late CameraComponent cam;
  Player player = Player(character: 'Pink Man');
  late JoystickComponent joystick;
  bool showControls = false;
  bool playSounds = true;
  double soundVolume = 1.0;
  List<String> levelNames = ['Level-01', 'Level-02', 'Level-03'];
  int currentLevelIndex = 0;

  @override
  FutureOr<void> onLoad() async {

    _configureAssetPrefixes();
    await images.loadAllImages();//loads all images into cache

    _loadLevel();

    if(showControls){
      addJoyStick();
      add(JumpButton());
    }

    return super.onLoad();
  }

  void _configureAssetPrefixes() {
    Flame.assets.prefix = 'packages/pixel_adventure/assets/';
    images.prefix = 'packages/pixel_adventure/assets/images/';
    FlameAudio.updatePrefix('packages/pixel_adventure/assets/audio/');
  }

  @override
  void update(double dt) {
    if(showControls){
      updateJoystick();
    }
    super.update(dt);
  }
  
  void addJoyStick() {
    joystick = JoystickComponent(
      priority: 20,
      knob: SpriteComponent(
        sprite: 
        Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      background: SpriteComponent(
        sprite: 
        Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),

      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );

    add(joystick);
  }
  
  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;

      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        //idle
        player.horizontalMovement = 0;
        
        break;
    }
  }

  void loadNextLevel(){

    removeWhere((component) => component is Level);

    if(currentLevelIndex < levelNames.length - 1){
      currentLevelIndex++;
      _loadLevel();
    } else {
      currentLevelIndex = 0;
      _loadLevel();
    }
  }
  
  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), (){
        Level world = Level(levelName: levelNames[currentLevelIndex], player: player);//calling our level constructor


        cam = CameraComponent.withFixedResolution(world: world, width: 640, height: 360);
        cam.viewfinder.anchor = Anchor.topLeft;

        addAll([cam, world]);
    });
  }
}
