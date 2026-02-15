
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'posts_screen.dart';
import 'yaml_editor_screen.dart';
import 'git_screen.dart';
import 'deploy_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PostsScreen(),
    const YamlEditorScreen(),
    const GitScreen(),
    const DeployScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FLBlog - Hexo Manager'),
        actions: [
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return IconButton(
                icon: Icon(
                  appProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => appProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(FontAwesomeIcons.filePen),
                      label: Text('文章'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('配置'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(FontAwesomeIcons.gitAlt),
                      label: Text('Git'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.rocket),
                      label: Text('部署'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.more_vert),
                      label: Text('更多'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _screens[_selectedIndex]),
              ],
            )
          : _screens[_selectedIndex],
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(FontAwesomeIcons.filePen),
                  label: '文章',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: '配置',
                ),
                NavigationDestination(
                  icon: Icon(FontAwesomeIcons.gitAlt),
                  label: 'Git',
                ),
                NavigationDestination(
                  icon: Icon(Icons.rocket),
                  label: '部署',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_vert),
                  label: '更多',
                ),
              ],
            )
          : null,
    );
  }
}

