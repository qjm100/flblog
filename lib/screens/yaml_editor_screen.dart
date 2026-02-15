

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../providers/app_provider.dart';
import '../services/file_service.dart';

class YamlEditorScreen extends StatefulWidget {
  const YamlEditorScreen({super.key});

  @override
  State<YamlEditorScreen> createState() => _YamlEditorScreenState();
}

class _YamlEditorScreenState extends State<YamlEditorScreen> {
  final FileService _fileService = FileService();
  final TextEditingController _contentController = TextEditingController();
  String? _currentFilePath;
  bool _isModified = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectYamlFile() async {
    if (!mounted) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    String? initialDirectory = appProvider.blogPath;

    final String? selectedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yml', 'yaml'],
      initialDirectory: initialDirectory,
    ).then((result) => result?.files.single.path);

    if (selectedFile != null && mounted) {
      await _loadFile(selectedFile);
    }
  }

  Future<void> _loadFile(String filePath) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await _fileService.readFile(filePath);
      if (content != null && mounted) {
        setState(() {
          _currentFilePath = filePath;
          _contentController.text = content;
          _isModified = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载文件失败: $e')),
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

  Future<void> _saveFile() async {
    if (_currentFilePath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _fileService.writeFile(_currentFilePath!, _contentController.text);
      if (mounted) {
        setState(() {
          _isModified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
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

  void _onContentChanged() {
    setState(() {
      _isModified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_currentFilePath != null
                ? path.basename(_currentFilePath!)
                : 'YAML 编辑器'),
            actions: [
              if (_isModified)
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveFile,
                  tooltip: '保存',
                ),
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _selectYamlFile,
                tooltip: '打开 YAML 文件',
              ),
            ],
          ),
          body: _buildBody(appProvider),
        );
      },
    );
  }

  Widget _buildBody(AppProvider appProvider) {
    if (appProvider.blogPath == null) {
      return _buildNoBlogPathState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentFilePath == null) {
      return _buildEmptyState();
    }

    return _buildEditor();
  }

  Widget _buildNoBlogPathState() {
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
            '请先选择博客目录',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.fileCode,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          const Text(
            '请选择一个 YAML 文件',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _selectYamlFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('打开 YAML 文件'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        if (_currentFilePath != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.file_present, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentFilePath!,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: TextField(
            controller: _contentController,
            onChanged: (_) => _onContentChanged(),
            decoration: const InputDecoration(
              hintText: '开始编辑 YAML 文件...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

