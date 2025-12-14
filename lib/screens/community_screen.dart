import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = true;
  String? _currentUserEmail;
  Map<String, List<Map<String, dynamic>>> _groupedResources = {};
  bool _isLoadingResources = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadCurrentUser();
    _fetchPosts();
    _fetchSafetyResources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('user_email');
    });
  }

  Future<void> _fetchPosts() async {
    try {
      setState(() {
        _isLoadingPosts = true;
      });

      final postsResponse = await Supabase.instance.client
          .from('community_posts')
          .select('*')
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      final posts = List<Map<String, dynamic>>.from(postsResponse);

      // Get likes for each post
      for (var post in posts) {
        // Get likes count
        final likesResponse = await Supabase.instance.client
            .from('post_likes')
            .select('id, user_email')
            .eq('post_id', post['id']);

        final likes = List<Map<String, dynamic>>.from(likesResponse);
        post['likes_count'] = likes.length;
        post['is_liked'] = _currentUserEmail != null &&
            likes.any((like) => like['user_email'] == _currentUserEmail);
      }

      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _fetchSafetyResources() async {
    try {
      setState(() {
        _isLoadingResources = true;
      });

      final response = await Supabase.instance.client
          .from('safety_resources')
          .select('*')
          .order('type', ascending: true);

      final resources = List<Map<String, dynamic>>.from(response);

      // Group resources by type
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final resource in resources) {
        final type = resource['type'] as String;
        if (!grouped.containsKey(type)) {
          grouped[type] = [];
        }
        grouped[type]!.add(resource);
      }

      setState(() {
        _groupedResources = grouped;
        _isLoadingResources = false;
      });
    } catch (e) {
      print('Error fetching safety resources: $e');
      setState(() {
        _isLoadingResources = false;
      });
    }
  }

  Future<void> _createPost(String title, String content, List<String> hashtags) async {
    if (_currentUserEmail == null) return;

    try {
      // Get user name from registrations table
      final userResponse = await Supabase.instance.client
          .from('registrations')
          .select('full_name')
          .eq('email', _currentUserEmail!)
          .maybeSingle();

      final userName = userResponse?['full_name'] ?? 'Anonymous';

      await Supabase.instance.client.from('community_posts').insert({
        'user_email': _currentUserEmail,
        'user_name': userName,
        'title': title,
        'content': content,
        'hashtags': hashtags,
        'status': 'pending',
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post submitted successfully! It will be visible after approval.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Don't refresh posts since pending posts aren't shown
    } catch (e) {
      print('Error creating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike(int postId, bool currentlyLiked) async {
    if (_currentUserEmail == null) return;

    try {
      if (currentlyLiked) {
        // Unlike
        await Supabase.instance.client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_email', _currentUserEmail!);
      } else {
        // Like
        await Supabase.instance.client.from('post_likes').insert({
          'post_id': postId,
          'user_email': _currentUserEmail,
        });
      }

      _fetchPosts(); // Refresh posts
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final hashtagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hashtagsController,
                  decoration: const InputDecoration(
                    labelText: 'Hashtags (comma separated)',
                    hintText: 'e.g., parenting, safety, tips',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                final hashtagsText = hashtagsController.text.trim();

                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in title and content')),
                  );
                  return;
                }

                final hashtags = hashtagsText.isEmpty
                    ? <String>[]
                    : hashtagsText.split(',').map((tag) => tag.trim().toLowerCase()).toList();

                _createPost(title, content, hashtags);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5C563),
                foregroundColor: Colors.black,
              ),
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onBackPressed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        if (mounted) context.go('/login');
        return;
      }

      final user = await Supabase.instance.client
          .from('registrations')
          .select('verification_status')
          .eq('email', email)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final normalized =
          (user?['verification_status'] ?? '').toString().trim().toLowerCase();

      if (normalized == 'verified' ||
          normalized == 'approve' ||
          normalized == 'approved') {
        context.go('/dashboard');
      } else {
        context.go('/status');
      }
    } catch (e) {
      print('ERROR: Back navigation failed - $e');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5C563),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _onBackPressed,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Image.asset(
                'assets/images/logo.png',
                height: 50,
                width: 50,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                indicatorColor: const Color(0xFF6B46C1),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Community'),
                  Tab(text: 'Explore resources'),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCommunityTab(),
                  _buildExploreResourcesTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _tabController.index == 0 ? FloatingActionButton.extended(
          onPressed: _showCreatePostDialog,
          backgroundColor: const Color(0xFFF5C563),
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Create post'),
        ) : null,
        bottomNavigationBar: const FooterWidget(),
      ),
    );
  }

  Widget _buildCommunityTab() {
    return RefreshIndicator(
      onRefresh: _fetchPosts,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Community Space Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Engage with our',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Community Space',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'where parents can share experiences,\nadvice, and support',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Show loading or posts
            if (_isLoadingPosts)
              const Center(child: CircularProgressIndicator())
            else if (_posts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text(
                    'No posts yet. Be the first to share!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._posts.map((post) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPostCard(post),
              )),
            const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final username = post['user_name'] ?? 'Anonymous';
    final createdAt = DateTime.parse(post['created_at']);
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}m ago';
    } else {
      timeAgo = 'Just now';
    }

    final tags = List<String>.from(post['hashtags'] ?? []);
    final title = post['title'] ?? '';
    final content = post['content'] ?? '';
    final likesCount = post['likes_count'] ?? 0;
    final isLiked = post['is_liked'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and tags
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$username • $timeAgo',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              Row(
                children: tags.map((tag) {
                  return Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B46C1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Content
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(post['id'], isLiked),
                child: Icon(
                  isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 18,
                  color: isLiked ? const Color(0xFF6B46C1) : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$likesCount',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(width: 20),
              Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '0', // Comments not implemented yet
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Spacer(),
              Icon(Icons.share_outlined, size: 18, color: Colors.grey.shade600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExploreResourcesTab() {
    return RefreshIndicator(
      onRefresh: _fetchSafetyResources,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resources Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Discover',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Safety Tips and Resources',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'on child safety, emergency procedures\nand best practices for parents',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Show loading or resources
              if (_isLoadingResources)
                const Center(child: CircularProgressIndicator())
              else if (_groupedResources.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      'No safety resources available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._groupedResources.entries.map((entry) {
                  final type = entry.key;
                  final resources = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._buildResourceRows(resources),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResourceRows(List<Map<String, dynamic>> resources) {
    final rows = <Widget>[];
    for (var i = 0; i < resources.length; i += 2) {
      final rowChildren = <Widget>[];
      rowChildren.add(
        Expanded(
          child: _buildResourceCardFromData(resources[i]),
        ),
      );
      if (i + 1 < resources.length) {
        rowChildren.add(const SizedBox(width: 12));
        rowChildren.add(
          Expanded(
            child: _buildResourceCardFromData(resources[i + 1]),
          ),
        );
      }
      rows.add(Row(children: rowChildren));
      if (i + 2 < resources.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return rows;
  }

  Widget _buildResourceCard({
    required String title,
    required String imagePath,
    required List<Color> colors,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Image (placeholder with error handling)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
          ),
          // Title overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCardFromData(Map<String, dynamic> resource) {
    final title = resource['description'] ?? 'No description';
    final imagePath = resource['image_link'] ?? '';
    final colors = _getGradientColorsForType(resource['type'] ?? '');

    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Image (placeholder with error handling)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imagePath.isNotEmpty ? Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ) : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Title overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColorsForType(String type) {
    switch (type.toLowerCase()) {
      case 'safety in public places':
        return [const Color(0xFFFEE2E2), const Color(0xFFFECDD3)];
      case 'home safety for children':
        return [const Color(0xFFFFEDD5), const Color(0xFFFED7AA)];
      case 'online safety':
        return [const Color(0xFFE0E7FF), const Color(0xFFDDD6FE)];
      case 'emergency preparedness':
        return [const Color(0xFFFEE2E2), const Color(0xFFFCA5A5)];
      default:
        return [const Color(0xFFE5E7EB), const Color(0xFFD1D5DB)];
    }
  }
}
