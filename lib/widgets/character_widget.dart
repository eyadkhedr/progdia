import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CharacterWidget extends StatelessWidget {
  final String? userId;
  final double size;
  const CharacterWidget({super.key, this.userId, this.size = 180});

  Future<Map<String, String?>> _fetchEquippedItems(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data() ?? {};
    if (data['equipped_items'] is Map) {
      return Map<String, String?>.from(data['equipped_items'] ?? {});
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    if (userId != null) {
      return FutureBuilder<Map<String, String?>>(
        future: _fetchEquippedItems(userId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              width: size,
              height: size,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildCharacter(context, snapshot.data!);
        },
      );
    } else {
      // For current user, you should pass equippedItems directly if available
      return _buildCharacter(context, {});
    }
  }

  Widget _buildCharacter(BuildContext context, Map<String, String?> equippedItems) {
    // If no items, show sloth base
    if (equippedItems.isEmpty || equippedItems.values.every((v) => v == null)) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset('assets/images/Sloth.png', fit: BoxFit.contain),
      );
    }
    // Otherwise, stack the equipped items
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/images/Sloth.png', width: size, height: size, fit: BoxFit.contain),
          if (equippedItems['hat'] != null)
            Image.asset(equippedItems['hat']!, width: size, height: size, fit: BoxFit.contain),
          if (equippedItems['shirt'] != null)
            Image.asset(equippedItems['shirt']!, width: size, height: size, fit: BoxFit.contain),
          if (equippedItems['jacket'] != null)
            Image.asset(equippedItems['jacket']!, width: size, height: size, fit: BoxFit.contain),
          if (equippedItems['pants']  != null)
            Image.asset(equippedItems['pants']!, width: size, height: size, fit: BoxFit.contain),
          if (equippedItems['shoes'] != null)
            Image.asset(equippedItems['shoes']!, width: size, height: size, fit: BoxFit.contain),
          if (equippedItems['tie'] != null)
            Image.asset(equippedItems['tie']!, width: size, height: size, fit: BoxFit.contain),
          if (equippedItems['glasses'] != null)
            Image.asset(equippedItems['glasses']!, width: size, height: size, fit: BoxFit.contain),
        ],
      ),
    );
  }
}
