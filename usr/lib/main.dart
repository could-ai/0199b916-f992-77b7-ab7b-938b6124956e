import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // The GameWidget is the Flutter widget that hosts the Flame game.
  runApp(GameWidget(game: EgoShooterGame()));
}

// The main game class, extending FlameGame and incorporating input mixins.
class EgoShooterGame extends FlameGame
    with HasKeyboardHandlerComponents, PointerMoveCallbacks, TapCallbacks {
  late Player player;
  Vector2 mousePosition = Vector2.zero();

  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create and add the player to the game.
    player = Player();
    add(player);
  }

  // Stores the current mouse position to be used for player aiming.
  @override
  void onPointerMove(PointerMoveEvent event) {
    mousePosition = event.localPosition;
  }

  // Handles shooting when the user clicks.
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // Create a new bullet instance when the screen is tapped.
    final bullet = Bullet(
      position: player.position.clone(),
      // The bullet's direction is from the player towards the mouse cursor.
      direction: (mousePosition - player.position).normalized(),
    );
    add(bullet);
  }
}

// The Player component.
class Player extends PositionComponent with KeyboardHandler {
  static const double speed = 200.0;
  final Paint paint = Paint()..color = Colors.white;
  Vector2 velocity = Vector2.zero();

  Player() {
    size = Vector2(40.0, 40.0);
    anchor = Anchor.center;
  }

  // Center the player on the screen when the game is resized.
  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = gameSize / 2;
  }

  // Renders the player as a triangle to indicate its direction.
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update the player's position based on its velocity.
    position += velocity * dt;

    // Rotate the player to face the mouse cursor.
    final game = findGame()! as EgoShooterGame;
    final direction = game.mousePosition - position;
    if (direction.length > 0) {
      // We subtract pi/2 because the triangle is pointing upwards.
      angle = atan2(direction.y, direction.x) - pi / 2;
    }
  }

  // Handles keyboard input for player movement (WASD).
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    Vector2 newVelocity = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
      newVelocity.y = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
      newVelocity.y = 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) {
      newVelocity.x = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) {
      newVelocity.x = 1;
    }

    // Normalize to prevent faster diagonal movement.
    if (newVelocity.length > 0) {
      newVelocity.normalize();
    }
    
    velocity = newVelocity * speed;
    
    return true;
  }
}

// The Bullet component.
class Bullet extends PositionComponent {
  static const double speed = 400.0;
  final Vector2 direction;
  final Paint paint = Paint()..color = Colors.yellow;

  Bullet({required Vector2 position, required this.direction}) {
    this.position = position;
    size = Vector2.all(10.0);
    anchor = Anchor.center;
  }

  // Renders the bullet as a small yellow circle.
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset.zero, size.x / 2, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Move the bullet in its direction.
    position += direction * speed * dt;

    // Remove the bullet if it goes off-screen to save resources.
    final game = findGame()!;
    if (position.x < 0 ||
        position.x > game.size.x ||
        position.y < 0 ||
        position.y > game.size.y) {
      removeFromParent();
    }
  }
}
