
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/blog_post.dart';
import '../providers/app_provider.dart';
import '../services/file_service.dart';

class EditorScreen extends StatefulWidget {
  final BlogPost post;

  const EditorScreen({super.key, required this.post});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final FileService _fileService = FileService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _categoriesController = TextEditingController();
  
  bool _isSaved = true;
  bool _showPreview = false;
  bool _showSplitView = true;
  Timer? _autoSaveTimer;
  late BlogPost _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _titleController.text = _currentPost.title;
    _contentController.text = _currentPost.content;
    _tagsController.text = _currentPost.tags.join(', ');
    _categoriesController.text = _currentPost.categories.join(', ');
    
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    _tagsController.addListener(_onChanged);
    _categoriesController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _categoriesController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    setState(() {
      _isSaved = false;
    });
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (_isSaved) return;
    await _savePost();
  }

  Future<void> _savePost() async {
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    
    final categories = _categoriesController.text
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    _currentPost = _currentPost.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      tags: tags,
      categories: categories,
      updated: DateTime.now(),
    );

    try {
      await _fileService.savePost(_currentPost);
      if (mounted) {
        setState(() {
          _isSaved = true;
        });
        Provider.of<AppProvider>(context, listen: false).updatePost(_currentPost);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isSaved,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_isSaved) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('有未保存的更改'),
              content: const Text('是否保存更改后退出？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('不保存'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _savePost();
                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          );
          if (shouldPop == true && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentPost.title),
          actions: [
            if (!_isSaved)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _savePost,
              ),
            _buildViewModeButton(),
          ],
        ),
        body: Column(
          children: [
            _buildMetadataSection(),
            const Divider(height: 1),
            Expanded(child: _buildEditorBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton() {
    return PopupMenuButton(
      icon: const Icon(Icons.view_module),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () {
            setState(() {
              _showSplitView = true;
              _showPreview = false;
            });
          },
          child: Row(
            children: [
              Icon(Icons.view_sidebar, color: _showSplitView ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(width: 8),
              const Text('分屏'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            setState(() {
              _showSplitView = false;
              _showPreview = false;
            });
          },
          child: Row(
            children: [
              Icon(Icons.edit, color: !_showSplitView && !_showPreview ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(width: 8),
              const Text('编辑'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            setState(() {
              _showSplitView = false;
              _showPreview = true;
            });
          },
          child: Row(
            children: [
              Icon(Icons.preview, color: _showPreview ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(width: 8),
              const Text('预览'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题',
              border: OutlineInputBorder(),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: '标签 (逗号分隔)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.tags),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _categoriesController,
                  decoration: const InputDecoration(
                    labelText: '分类 (逗号分隔)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorBody() {
    if (_showSplitView) {
      return Row(
        children: [
          Expanded(child: _buildEditor()),
          const VerticalDivider(width: 1),
          Expanded(child: _buildPreview()),
        ],
      );
    } else if (_showPreview) {
      return _buildPreview();
    } else {
      return _buildEditor();
    }
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        decoration: const InputDecoration(
          hintText: '开始编写你的文章...',
          border: InputBorder.none,
        ),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }

  Widget _buildPreview() {
    return MarkdownWidget(
      data: _contentController.text,
      config: MarkdownConfig(
        configs: [
          LinkConfig(
            onTap: (url) async {
              if (url != null && await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
    );
  }
}
