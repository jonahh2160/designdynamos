import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class PixelAdventureScreen extends StatefulWidget {
  const PixelAdventureScreen({super.key});

  @override
  State<PixelAdventureScreen> createState() => _PixelAdventureScreenState();
}

class _PixelAdventureScreenState extends State<PixelAdventureScreen> {
  late final PixelAdventure _game;

  @override
  void initState() {
    super.initState();
    _game = PixelAdventure();
    _initDevicePrefs();
  }

  Future<void> _initDevicePrefs() async {
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.35),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
