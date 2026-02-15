
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                        '博客设置',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.folder),
                        title: const Text('博客目录'),
                        subtitle: Text(appProvider.blogPath ?? '未选择'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectBlogPath(appProvider),
                      ),
                      ListTile(
                        leading: const Icon(Icons.article),
                        title: const Text('文章目录'),
                        subtitle: Text(appProvider.postsPath ?? '使用默认路径'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (appProvider.postsPath != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _clearPostsPath(appProvider),
                              ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => _selectPostsPath(appProvider),
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
                        '外观',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        secondary: Icon(
                          appProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        ),
                        title: const Text('深色模式'),
                        value: appProvider.isDarkMode,
                        onChanged: (value) => appProvider.toggleTheme(),
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
                        '关于',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const ListTile(
                        leading: Icon(Icons.info),
                        title: Text('版本'),
                        subtitle: Text('1.0.0'),
                      ),
                      ListTile(
                        leading: const Icon(FontAwesomeIcons.github),
                        title: const Text('GitHub'),
                        subtitle: const Text('查看源代码'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchUrl('https://github.com'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('文档'),
                        subtitle: const Text('查看使用文档'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchUrl('https://hexo.io/docs/'),
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
                        '帮助',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        leading: const Icon(Icons.help),
                        title: const Text('如何开始使用？'),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '1. 点击"博客目录"选择你的Hexo博客文件夹\n'
                              '2. 在"文章"页面查看和编辑你的博客文章\n'
                              '3. 在"配置"页面修改Hexo配置\n'
                              '4. 在"Git"页面配置版本控制\n'
                              '5. 在"部署"页面设置GitHub Pages自动部署',
                            ),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        leading: const Icon(Icons.question_answer),
                        title: const Text('常见问题'),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Q: 支持哪些Hexo主题？\n'
                              'A: 支持所有Hexo主题，可以在配置中设置主题名称。\n\n'
                              'Q: 如何备份配置？\n'
                              'A: 在配置页面点击"备份配置"按钮。\n\n'
                              'Q: 支持哪些Git操作？\n'
                              'A: 支持初始化、拉取、推送、提交等基本操作。',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectBlogPath(AppProvider appProvider) async {
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null && mounted) {
      await appProvider.setBlogPath(selectedDirectory);
    }
  }

  Future<void> _selectPostsPath(AppProvider appProvider) async {
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null && mounted) {
      await appProvider.setPostsPath(selectedDirectory);
    }
  }

  Future<void> _clearPostsPath(AppProvider appProvider) async {
    await appProvider.setPostsPath(null);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
