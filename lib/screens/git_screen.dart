
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../models/git_config.dart';
import '../services/git_service.dart';

class GitScreen extends StatefulWidget {
  const GitScreen({super.key});

  @override
  State<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends State<GitScreen> {
  final GitService _gitService = GitService();
  bool _isLoading = false;
  String? _statusOutput;
  String? _logOutput;

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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Git配置',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      _buildTextField(
                        controller: _remoteUrlController,
                        label: '远程仓库URL',
                        icon: FontAwesomeIcons.github,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _branchController,
                        label: '分支',
                        icon: Icons.merge_type,
                      ),
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
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _accessTokenController,
                        label: 'Access Token',
                        icon: Icons.key,
                        obscureText: true,
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
                        'Git操作',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    Widget? suffixIcon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      readOnly: readOnly,
      obscureText: obscureText,
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Git配置已保存')),
      );
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
    final repoPath = appProvider.gitConfig?.repoPath;
    if (repoPath == null || repoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置仓库路径')),
      );
      return;
    }

    try {
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
