import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class CommunityModerationScreen extends StatefulWidget {
  const CommunityModerationScreen({super.key});

  @override
  State<CommunityModerationScreen> createState() => _CommunityModerationScreenState();
}

class _CommunityModerationScreenState extends State<CommunityModerationScreen> {
  String _searchQuery = '';
  String _filter = 'ALL'; // 'ALL', 'PINNED', 'REPORTED'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Community Forum Moderation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search & Filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search posts, authors, keywords...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Posts')),
                          DropdownMenuItem(value: 'PINNED', child: Text('Pinned')),
                          DropdownMenuItem(value: 'REPORTED', child: Text('Reported/Spam')),
                        ],
                        onChanged: (val) => setState(() => _filter = val!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Posts List Stream
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getCommunityPostsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                    }

                    var posts = snapshot.data ?? [];

                    // Seed demo posts if empty
                    if (posts.isEmpty) {
                      posts = [
                        {
                          'postId': 'cp1',
                          'authorName': 'Rajesh Kumar',
                          'authorId': 'FAR1234',
                          'title': 'Best Fertilizer for Cotton Pest Resistance in Guntur?',
                          'content': 'Looking for recommended bio-fertilizers or neem sprays for cotton crop in Kharif season.',
                          'isPinned': true,
                          'likesCount': 24,
                          'repliesCount': 8,
                          'isReported': false,
                        },
                        {
                          'postId': 'cp2',
                          'authorName': 'Anonymous User',
                          'authorId': 'FAR999',
                          'title': 'Buy Unregistered Pesticide Cheap Rate Call Now',
                          'content': 'Promotional spam link for unauthorized non-standard chemicals.',
                          'isPinned': false,
                          'likesCount': 0,
                          'repliesCount': 1,
                          'isReported': true,
                        },
                      ];
                    }

                    // Filter
                    posts = posts.where((p) {
                      final title = (p['title'] ?? '').toString().toLowerCase();
                      final content = (p['content'] ?? '').toString().toLowerCase();
                      final author = (p['authorName'] ?? '').toString().toLowerCase();
                      final q = _searchQuery.toLowerCase();

                      final matchesSearch = title.contains(q) || content.contains(q) || author.contains(q);
                      final isPinned = p['isPinned'] ?? false;
                      final isReported = p['isReported'] ?? false;

                      final matchesFilter = _filter == 'ALL' || (_filter == 'PINNED' && isPinned) || (_filter == 'REPORTED' && isReported);
                      return matchesSearch && matchesFilter;
                    }).toList();

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final p = posts[index];
                        final isPinned = p['isPinned'] ?? false;
                        final isReported = p['isReported'] ?? false;

                        return Card(
                          color: isReported ? Colors.red.shade50 : Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isReported ? Colors.redAccent.withValues(alpha: 0.3) : Colors.transparent),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                      child: Text((p['authorName'] ?? 'F')[0], style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['authorName'] as String? ?? 'Farmer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text('Author ID: ${p['authorId']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    if (isPinned) const Icon(Icons.push_pin_rounded, color: AppTheme.accentGold, size: 20),
                                    if (isReported)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('SPAM ALERT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(p['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(p['content'] as String? ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text('${p['likesCount'] ?? 0} Likes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(width: 16),
                                    Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text('${p['repliesCount'] ?? 0} Replies', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: AppTheme.accentGold),
                                      onPressed: () async {
                                        await FirestoreService().pinOrFeatureCommunityPost(p['postId'], isPinned: !isPinned);
                                      },
                                      tooltip: isPinned ? 'Unpin Post' : 'Pin Post to Top',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                      onPressed: () => _deletePost(p['postId'], p['title'] ?? 'Post'),
                                      tooltip: 'Delete Post',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePost(String postId, String title) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Forum Post?'),
        content: Text('Are you sure you want to remove "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().deleteCommunityPost(postId);
              await FirestoreService().logAuditEvent(
                userId: 'ADMIN',
                action: 'Deleted Forum Post',
                category: 'ADMIN',
                details: 'Deleted community post: $title',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
