import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../models/git_config.dart';
import '../services/git_service.dart';
import '../services/github_api_service.dart';

class GitScreen extends StatefulWidget {
  const GitScreen({super.key});

  @override
  State<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends State<GitScreen> {
  late GitService _gitService;
  bool _isLoading = false;
  String? _statusOutput;
  String? _logOutput;
  bool _isApiMode = false;

  final _repoPathController = TextEditingController();
  final _remoteUrlController = TextEditingController();
  final _branchController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _accessTokenController = TextEditingController();
  final _commitMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isApiMode = !Platform.isLinux && !Platform.isWindows && !Platform.isMacOS;
    _gitService = GitService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGitConfig();
    });
  }

  @override
  void dispose() {
    _repoPathController.dispose();
    _remoteUrlController.dispose();
    _branchController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _accessTokenController.dispose();
    _commitMessageController.dispose();
    super.dispose();
  }

  void _loadGitConfig() {
    if (!mounted) return;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final config = appProvider.gitConfig;
    if (config != null) {
      _repoPathController.text = config.repoPath ?? '';
      _remoteUrlController.text = config.remoteUrl ?? '';
      _branchController.text = config.branch ?? 'main';
      _usernameController.text = config.username ?? '';
      _emailController.text = config.email ?? '';
      _accessTokenController.text = config.accessToken ?? '';
    }
    
    _initGitService();
  }

  void _initGitService() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final accessToken = appProvider.gitConfig?.accessToken;
    
    if (_isApiMode && accessToken != null && accessToken.isNotEmpty) {
      final apiService = GitHubApiService(accessToken: accessToken);
      _gitService = GitService(apiService: apiService);
    } else {
      _gitService = GitService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_isApiMode) ...[
                _buildApiModeBanner(),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isApiMode ? 'GitHub API配置' : 'Git配置',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!_isApiMode) ...[
                        _buildTextField(
                          controller: _repoPathController,
                          label: '仓库路径',
                          icon: Icons.folder,
                          readOnly: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () => _selectRepoPath(appProvider),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildTextField(
                        controller: _remoteUrlController,
                        label: 'GitHub仓库URL',
                        icon: FontAwesomeIcons.github,
                        hint: 'https://github.com/username/repo',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _branchController,
                        label: '分支',
                        icon: Icons.merge_type,
                      ),
                      if (!_isApiMode) ...[
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _usernameController,
                          label: '用户名',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emailController,
                          label: '邮箱',
                          icon: Icons.email,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _accessTokenController,
                        label: 'GitHub Access Token',
                        icon: Icons.key,
                        obscureText: true,
                        hint: '需要repo权限的Personal Access Token',
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _openTokenHelp,
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text('如何获取Access Token?'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _saveGitConfig(appProvider),
                        icon: const Icon(Icons.save),
                        label: const Text('保存配置'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isApiMode ? 'GitHub操作' : 'Git操作',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isApiMode) ...[
                        _buildApiOperations(appProvider),
                      ] else ...[
                        _buildGitOperations(appProvider),
                      ],
                    ],
                  ),
                ),
              ),
              if (_statusOutput != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '状态',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            _statusOutput!,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_logOutput != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '提交历史',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            _logOutput!,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildApiModeBanner() {
    return Card(
      color: Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '移动端使用GitHub API模式，无需安装Git。请配置Access Token以使用同步功能。',
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiOperations(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '文件同步',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commitMessageController,
          decoration: const InputDecoration(
            labelText: '提交信息',
            border: OutlineInputBorder(),
            hintText: '输入本次同步的描述',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _syncCurrentPost(appProvider),
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('同步当前文章'),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _getLog(appProvider),
              icon: const Icon(Icons.history),
              label: const Text('查看历史'),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _getBranches(appProvider),
              icon: const Icon(Icons.list),
              label: const Text('查看分支'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGitOperations(AppProvider appProvider) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _initRepo(appProvider),
              icon: const Icon(Icons.add),
              label: const Text('初始化仓库'),
            ),
            ElevatedButton.icon(
              onPressed: () => _pull(appProvider),
              icon: const Icon(Icons.download),
              label: const Text('拉取'),
            ),
            ElevatedButton.icon(
              onPressed: () => _push(appProvider),
              icon: const Icon(Icons.upload),
              label: const Text('推送'),
            ),
            ElevatedButton.icon(
              onPressed: () => _getStatus(appProvider),
              icon: const Icon(Icons.info),
              label: const Text('状态'),
            ),
            ElevatedButton.icon(
              onPressed: () => _getLog(appProvider),
              icon: const Icon(Icons.history),
              label: const Text('日志'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commitMessageController,
          decoration: const InputDecoration(
            labelText: '提交信息',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _commit(appProvider),
          icon: const Icon(Icons.check),
          label: const Text('提交'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    Widget? suffixIcon,
    bool obscureText = false,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
        hintText: hint,
      ),
      readOnly: readOnly,
      obscureText: obscureText,
    );
  }

  void _openTokenHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('如何获取GitHub Access Token'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. 登录 GitHub.com'),
              Text('2. 点击右上角头像 → Settings'),
              Text('3. 左侧菜单最下方 → Developer settings'),
              Text('4. 选择 Personal access tokens → Tokens (classic)'),
              Text('5. 点击 Generate new token (classic)'),
              Text('6. 填写Note，选择过期时间'),
              Text('7. 勾选 repo 权限（完整仓库访问权限）'),
              Text('8. 点击 Generate token'),
              Text('9. 复制生成的token（只显示一次）'),
              SizedBox(height: 16),
              Text('⚠️ 注意：Token只会在创建时显示一次，请妥善保存！'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRepoPath(AppProvider appProvider) async {
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null && mounted) {
      _repoPathController.text = selectedDirectory;
      final config = (appProvider.gitConfig ?? GitConfig()).copyWith(repoPath: selectedDirectory);
      await appProvider.setGitConfig(config);
    }
  }

  Future<void> _saveGitConfig(AppProvider appProvider) async {
    final config = GitConfig(
      repoPath: _repoPathController.text,
      remoteUrl: _remoteUrlController.text,
      branch: _branchController.text,
      username: _usernameController.text,
      email: _emailController.text,
      accessToken: _accessTokenController.text,
    );

    await appProvider.setGitConfig(config);
    _initGitService();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
    }
  }

  Future<void> _syncCurrentPost(AppProvider appProvider) async {
    final currentPost = appProvider.currentPost;
    if (currentPost == null || currentPost.filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要同步的文章')),
      );
      return;
    }

    final remoteUrl = appProvider.gitConfig?.remoteUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置GitHub仓库URL')),
      );
      return;
    }

    final accessToken = appProvider.gitConfig?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置Access Token')),
      );
      return;
    }

    if (_commitMessageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入提交信息')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final blogPath = appProvider.blogPath;
      final relativePath = currentPost.filePath!.replaceFirst('$blogPath/', '');
      
      final result = await _gitService.syncFile(
        remoteUrl: remoteUrl,
        localPath: currentPost.filePath!,
        relativePath: relativePath,
        message: _commitMessageController.text,
        branch: appProvider.gitConfig?.branch ?? 'main',
      );

      _commitMessageController.clear();
      setState(() {
        _statusOutput = result;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getBranches(AppProvider appProvider) async {
    final remoteUrl = appProvider.gitConfig?.remoteUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置GitHub仓库URL')),
      );
      return;
    }

    try {
      final branches = await _gitService.getBranches(remoteUrl);
      setState(() {
        _statusOutput = '分支列表:\n${branches.join('\n')}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取分支失败: $e')),
        );
      }
    }
  }

  Future<void> _initRepo(AppProvider appProvider) async {
    final repoPath = appProvider.gitConfig?.repoPath;
    if (repoPath == null || repoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置仓库路径')),
      );
      return;
    }

    try {
      await _gitService.initRepo(repoPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('仓库初始化成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败: $e')),
        );
      }
    }
  }

  Future<void> _pull(AppProvider appProvider) async {
    final repoPath = appProvider.gitConfig?.repoPath;
    if (repoPath == null || repoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置仓库路径')),
      );
      return;
    }

    try {
      final output = await _gitService.pull(
        repoPath,
        branch: appProvider.gitConfig?.branch,
      );
      setState(() {
        _statusOutput = '拉取成功:\n$output';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('拉取成功')),
        );
      }
    } catch (e) {
      setState(() {
        _statusOutput = '拉取失败:\n$e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拉取失败: $e')),
        );
      }
    }
  }

  Future<void> _push(AppProvider appProvider) async {
    final repoPath = appProvider.gitConfig?.repoPath;
    if (repoPath == null || repoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置仓库路径')),
      );
      return;
    }

    try {
      final output = await _gitService.push(
        repoPath,
        branch: appProvider.gitConfig?.branch,
        setUpstream: true,
      );
      setState(() {
        _statusOutput = '推送成功:\n$output';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('推送成功')),
        );
      }
    } catch (e) {
      setState(() {
        _statusOutput = '推送失败:\n$e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('推送失败: $e')),
        );
      }
    }
  }

  Future<void> _commit(AppProvider appProvider) async {
    final repoPath = appProvider.gitConfig?.repoPath;
    if (repoPath == null || repoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置仓库路径')),
      );
      return;
    }
    if (_commitMessageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入提交信息')),
      );
      return;
    }

    try {
      await _gitService.addAll(repoPath);
      final output = await _gitService.commit(
        repoPath,
        _commitMessageController.text,
      );
      _commitMessageController.clear();
      setState(() {
        _statusOutput = '提交成功:\n$output';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提交成功')),
        );
      }
    } catch (e) {
      setState(() {
        _statusOutput = '提交失败:\n$e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    }
  }

  Future<void> _getStatus(AppProvider appProvider) async {
    final repoPath = appProvider.gitConfig?.repoPath;
    if (repoPath == null || repoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置仓库路径')),
      );
      return;
    }

    try {
      final status = await _gitService.getStatus(repoPath);
      setState(() {
        _statusOutput = status;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取状态失败: $e')),
        );
      }
    }
  }

  Future<void> _getLog(AppProvider appProvider) async {
    try {
      final repoPath = _isApiMode 
          ? appProvider.gitConfig?.remoteUrl ?? '' 
          : appProvider.gitConfig?.repoPath ?? '';
      
      if (repoPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isApiMode ? '请先配置GitHub仓库URL' : '请先配置仓库路径')),
        );
        return;
      }

      final log = await _gitService.getLog(repoPath);
      setState(() {
        _logOutput = log;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取日志失败: $e')),
        );
      }
    }
  }
}
