import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
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

      for (var post in posts) {
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

  Future<void> _createPost(String title, String content, List<String> hashtags, File? imageFile) async {
    if (_currentUserEmail == null) return;

    try {
      final userResponse = await Supabase.instance.client
          .from('registrations')
          .select('full_name')
          .eq('email', _currentUserEmail!)
          .maybeSingle();

      final userName = userResponse?['full_name'] ?? 'Anonymous';

      String? imageUrl;
      if (imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_currentUserEmail}';
        final path = 'community_images/$fileName';

        await Supabase.instance.client.storage.from('community-images').upload(path, imageFile);

        final response = Supabase.instance.client.storage.from('community-images').getPublicUrl(path);
        imageUrl = response;
      }

      await Supabase.instance.client.from('community_posts').insert({
        'user_email': _currentUserEmail,
        'user_name': userName,
        'title': title,
        'content': content,
        'hashtags': hashtags,
        'image_url': imageUrl,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post submitted successfully! It will be visible after approval.'),
            backgroundColor: Colors.green,
          ),
        );
      }

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
        await Supabase.instance.client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_email', _currentUserEmail!);
      } else {
        await Supabase.instance.client.from('post_likes').insert({
          'post_id': postId,
          'user_email': _currentUserEmail,
        });
      }

      _fetchPosts();
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _sharePost(Map<String, dynamic> post) async {
    final title = post['title'] ?? '';
    final content = post['content'] ?? '';
    final shareText = '$title\n\n$content\n\nShared from PolisMitr Community';

    try {
      await Share.share(shareText, subject: title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share post: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Full screen image
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.white, size: 60),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              // Tap to close hint
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pinch to zoom • Tap outside to close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final hashtagsController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1920,
                          maxHeight: 1920,
                          imageQuality: 85,
                        );
                        if (pickedFile != null) {
                          setDialogState(() {
                            selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: selectedImage != null ? 200 : 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: selectedImage != null
                            ? Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          selectedImage = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 30,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Image',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
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

                    _createPost(title, content, hashtags, selectedImage);
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
          // User info and tags row
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

          // Two column layout for content and image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Content (takes 2/3 space)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Like count
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
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right column - Image and Share (takes 1/3 space)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Image with tap to view full screen
                    if (post['image_url'] != null && post['image_url'].toString().isNotEmpty)
                      GestureDetector(
                        onTap: () => _showFullScreenImage(context, post['image_url']),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post['image_url'],
                            width: double.infinity,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    if (post['image_url'] != null && post['image_url'].toString().isNotEmpty)
                      const SizedBox(height: 8),

                    // Share button - icon only
                    GestureDetector(
                      onTap: () => _sharePost(post),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imagePath.isNotEmpty
                  ? (imagePath.startsWith('http')
                      ? Image.network(
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
                        )
                      : Image.asset(
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
                        ))
                  : Container(
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
