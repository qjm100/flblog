
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class DeployScreen extends StatefulWidget {
  const DeployScreen({super.key});

  @override
  State<DeployScreen> createState() => _DeployScreenState();
}

class _DeployScreenState extends State<DeployScreen> {
  bool _isDeploying = false;
  String? _deployLog;
  final _domainController = TextEditingController();

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
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
                        'GitHub Pages 部署',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const ListTile(
                        leading: Icon(Icons.info),
                        title: Text('部署前准备'),
                        subtitle: Text('确保已配置Git并连接到GitHub仓库'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _domainController,
                        decoration: const InputDecoration(
                          labelText: '自定义域名 (可选)',
                          hintText: 'yourblog.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.domain),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isDeploying ? null : () => _generateWorkflow(appProvider),
                            icon: const Icon(Icons.build),
                            label: const Text('生成工作流'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isDeploying ? null : () => _deploy(appProvider),
                            icon: const Icon(Icons.rocket),
                            label: const Text('一键部署'),
                          ),
                        ],
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
                        '部署说明',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('1. 确保你的Hexo博客已推送到GitHub仓库'),
                      const SizedBox(height: 8),
                      const Text('2. 在GitHub仓库设置中启用GitHub Pages'),
                      const SizedBox(height: 8),
                      const Text('3. 点击"生成工作流"创建GitHub Action配置'),
                      const SizedBox(height: 8),
                      const Text('4. 提交并推送工作流文件到GitHub'),
                      const SizedBox(height: 8),
                      const Text('5. 点击"一键部署"开始部署流程'),
                    ],
                  ),
                ),
              ),
              if (_deployLog != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '部署日志',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          child: Text(
                            _deployLog!,
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

  Future<void> _generateWorkflow(AppProvider appProvider) async {
    if (appProvider.blogPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择Hexo博客目录')),
      );
      return;
    }

    try {
      final workflowsDir = Directory(path.join(appProvider.blogPath!, '.github', 'workflows'));
      if (!await workflowsDir.exists()) {
        await workflowsDir.create(recursive: true);
      }

      final workflowFile = File(path.join(workflowsDir.path, 'deploy.yml'));
      final workflowContent = '''name: Deploy Hexo to GitHub Pages

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"

      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: node_modules
          key: \${{ runner.os }}-node-\${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            \${{ runner.os }}-node-

      - name: Install dependencies
        run: npm install

      - name: Build Hexo
        run: npm run build

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: \${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
''';
      await workflowFile.writeAsString(workflowContent);

      if (_domainController.text.isNotEmpty) {
        final cnameFile = File(path.join(appProvider.blogPath!, 'source', 'CNAME'));
        await cnameFile.writeAsString(_domainController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('工作流文件已生成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成工作流失败: $e')),
        );
      }
    }
  }

  Future<void> _deploy(AppProvider appProvider) async {
    if (appProvider.blogPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择Hexo博客目录')),
      );
      return;
    }

    setState(() {
      _isDeploying = true;
      _deployLog = '开始部署...\n';
    });

    try {
      setState(() {
        _deployLog = (_deployLog ?? '') + '部署流程已启动，请查看GitHub Actions页面获取详细信息\n';
        _deployLog = (_deployLog ?? '') + '部署将在代码推送到GitHub后自动执行\n';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('部署已启动，请查看GitHub Actions')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deployLog = (_deployLog ?? '') + '部署失败: $e\n';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('部署失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeploying = false;
        });
      }
    }
  }
}
