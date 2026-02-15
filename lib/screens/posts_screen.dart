
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../models/blog_post.dart';
import '../services/file_service.dart';
import 'editor_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final FileService _fileService = FileService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          body: appProvider.blogPath == null
              ? _buildEmptyState(context, appProvider)
              : _buildPostList(context, appProvider),
          floatingActionButton: appProvider.blogPath != null
              ? FloatingActionButton.extended(
                  onPressed: () => _createNewPost(context, appProvider),
                  icon: const Icon(Icons.add),
                  label: const Text('新建文章'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider appProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.folderOpen,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            '请选择Hexo博客目录',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _selectBlogPath(context, appProvider),
            icon: const Icon(Icons.folder),
            label: const Text('选择目录'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context, AppProvider appProvider) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appProvider.posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadPosts(appProvider),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.fileLines,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无文章',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _loadPosts(appProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPosts(appProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appProvider.posts.length,
        itemBuilder: (context, index) {
          final post = appProvider.posts[index];
          return _PostCard(
            post: post,
            onTap: () => _editPost(context, appProvider, post),
            onDelete: () => _deletePost(context, appProvider, post),
          );
        },
      ),
    );
  }

  Future<void> _selectBlogPath(BuildContext context, AppProvider appProvider) async {
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null && mounted) {
      await appProvider.setBlogPath(selectedDirectory);
      if (mounted) {
        await _loadPosts(appProvider);
      }
    }
  }

  Future<void> _loadPosts(AppProvider appProvider) async {
    if (appProvider.blogPath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await _fileService.scanPosts(
        appProvider.blogPath!,
        postsPath: appProvider.postsPath,
      );
      appProvider.setPosts(posts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载文章失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewPost(BuildContext context, AppProvider appProvider) async {
    final titleController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文章'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '文章标题',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final post = await _fileService.createPost(
          appProvider.blogPath!,
          result,
          postsPath: appProvider.postsPath,
        );
        appProvider.addPost(post);
        if (mounted) {
          _editPost(context, appProvider, post);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建文章失败: $e')),
          );
        }
      }
    }
  }

  void _editPost(BuildContext context, AppProvider appProvider, BlogPost post) {
    appProvider.setCurrentPost(post);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(post: post),
      ),
    ).then((_) {
      _loadPosts(appProvider);
    });
  }

  Future<void> _deletePost(BuildContext context, AppProvider appProvider, BlogPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除文章"${post.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _fileService.deletePost(post.filePath!);
        appProvider.removePost(post.filePath!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文章已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
}

class _PostCard extends StatelessWidget {
  final BlogPost post;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (post.date != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.date!.year}-${post.date!.month.toString().padLeft(2, '0')}-${post.date!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (post.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: post.tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
