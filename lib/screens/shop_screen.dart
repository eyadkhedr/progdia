import 'package:flutter/material.dart';
import '../widgets/stats_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/character_widget.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Hats',
    'Shirts',
    'Pants',
    'Shoes',
    'Accessories'
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getItemCategory(String type) {
    switch (type) {
      case 'hat':
        return 'Hats';
      case 'shirt':
      case 'jacket':
        return 'Shirts';
      case 'pants':
      case 'skirt':
        return 'Pants';
      case 'shoes':
        return 'Shoes';
      case 'tie':
      case 'glasses':
        return 'Accessories';
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: Text('Not signed in'))),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return Center(child: Text('Error loading user data'));
            }
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final equippedItems = (userData['equipped_items'] is Map)
                ? Map<String, String?>.from(userData['equipped_items'] ?? {})
                : <String, String?>{};
            final ownedItems = (userData['owned_items'] is List)
                ? List<String>.from(userData['owned_items'] ?? [])
                : <String>[];
            final coins = (userData['coins'] is int) ? userData['coins'] : 0;

            return Column(
              children: [
                // Stats Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: const StatsBar(),
                ),

                // Character Preview (Pinned)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withAlpha(120),
                          width: 1.2,
                        ),
                      ),
                      child: CharacterWidget(
                        userId: user.uid,
                        size: screenWidth - 40,
                      ),
                    ),
                  ),
                ),

                // Category Filter Chips with Fade Effect
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withAlpha(0),
                        Theme.of(context).colorScheme.surface.withAlpha(0),
                        Theme.of(context).colorScheme.surface,
                      ],
                      stops: const [0.0, 0.05, 0.95, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstOut,
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = isSelected ? 'All' : category;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer.withAlpha(38)
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withAlpha(77)
                                  : Theme.of(context).colorScheme.outline.withAlpha(31),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withAlpha(178),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Items Grid with Fade Effect
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withAlpha(0),
                          Theme.of(context).colorScheme.surface.withAlpha(0),
                          Theme.of(context).colorScheme.surface,
                        ],
                        stops: const [0.0, 0.05, 0.95, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstOut,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('shop_items').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading shop items'));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final items = snapshot.data!.docs.where((doc) {
                          if (_selectedCategory == 'All') return true;
                          final item = doc.data() as Map<String, dynamic>? ?? {};
                          return _getItemCategory(item['type'] ?? '') == _selectedCategory;
                        }).toList();

                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              'No ${_selectedCategory.toLowerCase()} available',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(153)
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index].data() as Map<String, dynamic>? ?? {};
                            final itemId = items[index].id;
                            final owned = ownedItems.contains(itemId);
                            final equipped = equippedItems[item['type']] == item['image'];

                            return _ShopItemCard(
                              item: item,
                              itemId: itemId,
                              owned: owned,
                              equipped: equipped,
                              coins: coins,
                              userId: user.uid,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final String itemId;
  final bool owned;
  final bool equipped;
  final int coins;
  final String userId;

  const _ShopItemCard({
    required this.item,
    required this.itemId,
    required this.owned,
    required this.equipped,
    required this.coins,
    required this.userId,
  });

  @override
  State<_ShopItemCard> createState() => _ShopItemCardState();
}

class _ShopItemCardState extends State<_ShopItemCard> {
  bool loading = false;

  Future<void> _buyItem() async {
    setState(() => loading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final data = doc.data() ?? {};
      final currentCoins = (data['coins'] is int) ? data['coins'] : 0;
      final price = (widget.item['price'] is int) ? widget.item['price'] : 0;

      if (currentCoins < price) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough coins!')),
        );
        setState(() => loading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'coins': FieldValue.increment(-price),
        'owned_items': FieldValue.arrayUnion([widget.itemId]),
      });
    } catch (e, st) {
      debugPrint('Error buying item: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error buying item: $e')),
      );
    }
    setState(() => loading = false);
  }

  Future<void> _equipItem() async {
    setState(() => loading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'equipped_items.${widget.item['type']}': widget.item['image'],
      });
    } catch (e, st) {
      debugPrint('Error equipping item: $e\n$st');
    }
    setState(() => loading = false);
  }

  Future<void> _unequipItem() async {
    setState(() => loading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'equipped_items.${widget.item['type']}': FieldValue.delete(),
      });
    } catch (e, st) {
      debugPrint('Error unequipping item: $e\n$st');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(120),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.asset(
                (widget.item['displayed_image'] ?? widget.item['image']) ?? 'assets/images/Sloth.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!widget.owned)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, 
                  color: widget.coins >= (widget.item['price'] ?? 0)
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withAlpha(120),
                  size: 20
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.item['price'] ?? '-'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.coins >= (widget.item['price'] ?? 0)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withAlpha(120),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          if (widget.owned)
            widget.equipped
                ? SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: loading ? null : _unequipItem,
                      icon: loading 
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Icon(Icons.check_circle, size: 18),
                      label: Text('Equipped'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withAlpha(120),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: loading ? null : _equipItem,
                      icon: loading 
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Icon(Icons.checkroom, size: 18),
                      label: Text('Equip'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (widget.coins >= (widget.item['price'] ?? 0) && !loading) ? _buyItem : null,
                icon: loading 
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Icon(Icons.shopping_cart_outlined, size: 18),
                label: Text('Buy'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 