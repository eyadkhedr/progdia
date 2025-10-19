import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../widgets/stats_bar.dart';
import '../widgets/character_widget.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    friendsProvider.fetchFriends();
    friendsProvider.fetchFriendRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => const _SearchFriendDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: _showSearchDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.search, color: Colors.white),
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      const StatsBar(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Friends'),
                      Tab(text: 'Requests'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsList(friendsProvider),
              _buildFriendRequestsList(friendsProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(FriendsProvider provider) {
    if (provider.friends.isEmpty) {
      return const Center(child: Text('Add friends to see them here!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.friends.length,
      itemBuilder: (context, index) {
        final friend = provider.friends[index];
        return GestureDetector(
          onLongPress: () => _showDeleteFriendDialog(friend),
          child: _buildFriendCard(friend),
        );
      },
    );
  }

  Widget _buildFriendRequestsList(FriendsProvider provider) {
    if (provider.friendRequests.isEmpty) {
      return const Center(child: Text('No pending friend requests.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.friendRequests.length,
      itemBuilder: (context, index) {
        final request = provider.friendRequests[index];
        final senderId = request['senderId'];
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final sender = AppUser.fromFirestore(snapshot.data!);
            return _buildRequestCard(sender, provider);
          },
        );
      },
    );
  }

  Widget _buildFriendCard(AppUser friend) {
    return _buildCard(
      context: context,
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _showFriendCharacterScreen(friend),
          child: CharacterWidget(userId: friend.uid, size: 70),
        ),
        title: Text(friend.username, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
            const SizedBox(width: 4),
            Text('${friend.coins}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Icon(Icons.local_fire_department_rounded, color: Theme.of(context).colorScheme.secondary, size: 16),
            const SizedBox(width: 4),
            Text('${friend.streak}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showDeleteFriendDialog(AppUser friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Friend'),
        content: Text('Are you sure you want to delete ${friend.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<FriendsProvider>(context, listen: false)
                  .deleteFriend(friend.uid);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(AppUser sender, FriendsProvider provider) {
    return _buildCard(
      context: context,
      child: ListTile(
        leading: const CharacterWidget(),
        title: Text(sender.username, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => provider.acceptFriendRequest(sender.uid),
              tooltip: 'Accept',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => provider.rejectFriendRequest(sender.uid),
              tooltip: 'Reject',
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendCharacterScreen(AppUser friend) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CharacterWidget(userId: friend.uid, size: 340),
              const SizedBox(height: 24),
              Text(friend.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 4),
                  Text('${friend.coins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 16),
                  Icon(Icons.local_fire_department_rounded, color: Theme.of(context).colorScheme.secondary, size: 20),
                  const SizedBox(width: 4),
                  Text('${friend.streak}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildCard({required BuildContext context, required Widget child}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withAlpha(120),
        width: 1.5,
      ),
    ),
    child: child,
  );
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _SearchFriendDialog extends StatefulWidget {
  const _SearchFriendDialog();

  @override
  State<_SearchFriendDialog> createState() => _SearchFriendDialogState();
}

class _SearchFriendDialogState extends State<_SearchFriendDialog> {
  final _searchController = TextEditingController();
  AppUser? _searchedUser;
  bool _isLoading = false;
  bool _userNotFound = false;
  bool _searchSuccess = false;

  void _searchUser() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _isLoading = true;
      _userNotFound = false;
      _searchedUser = null;
      _searchSuccess = false;
    });

    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final user = await provider.searchUserByUsername(username);

    setState(() {
      if (user == null) {
        _userNotFound = true;
        _searchSuccess = false;
      } else {
        _searchedUser = user;
        _searchSuccess = true;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDialogWidth = 400.0;
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDialogWidth),
          child: _buildCard(
            context: context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter username...',
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                                ),
                              )
                            : (_searchController.text.isNotEmpty && !_isLoading
                                ? (_searchSuccess
                                    ? Icon(Icons.check_circle, color: Colors.green, size: 22)
                                    : (_userNotFound
                                        ? Icon(Icons.error, color: theme.colorScheme.error, size: 22)
                                        : null))
                                : null),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _userNotFound = false;
                          _searchedUser = null;
                          _searchSuccess = false;
                        });
                      },
                      onSubmitted: (_) => _searchUser(),
                      textInputAction: TextInputAction.search,
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _userNotFound
                      ? const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text('User not found.', style: TextStyle(color: Colors.red)),
                        )
                      : const SizedBox(height: 0),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  )
                else if (_searchedUser != null)
                  ListTile(
                    leading: const CharacterWidget(),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _searchedUser!.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Provider.of<FriendsProvider>(context, listen: false)
                            .sendFriendRequest(_searchedUser!.uid);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Friend request sent to ${_searchedUser!.username}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                        elevation: 0,
                      ),
                      child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
