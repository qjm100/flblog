
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blog_post.dart';
import '../models/git_config.dart';

class AppProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String? _blogPath;
  String? _postsPath;
  List<BlogPost> _posts = [];
  GitConfig? _gitConfig;
  BlogPost? _currentPost;

  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String? get blogPath => _blogPath;
  String? get postsPath => _postsPath;
  List<BlogPost> get posts => _posts;
  GitConfig? get gitConfig => _gitConfig;
  BlogPost? get currentPost => _currentPost;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
    _loadBlogPath();
    _loadPostsPath();
    _loadGitConfig();
  }

  void _loadTheme() {
    _isDarkMode = _prefs?.getBool('darkMode') ?? false;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs?.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  void _loadBlogPath() {
    _blogPath = _prefs?.getString('blogPath');
  }

  Future<void> setBlogPath(String path) async {
    _blogPath = path;
    await _prefs?.setString('blogPath', path);
    notifyListeners();
  }

  void _loadPostsPath() {
    _postsPath = _prefs?.getString('postsPath');
  }

  Future<void> setPostsPath(String? path) async {
    _postsPath = path;
    if (path != null) {
      await _prefs?.setString('postsPath', path);
    } else {
      await _prefs?.remove('postsPath');
    }
    notifyListeners();
  }

  void _loadGitConfig() {
    final repoPath = _prefs?.getString('gitRepoPath');
    final remoteUrl = _prefs?.getString('gitRemoteUrl');
    final branch = _prefs?.getString('gitBranch');
    final username = _prefs?.getString('gitUsername');
    final email = _prefs?.getString('gitEmail');
    final accessToken = _prefs?.getString('gitAccessToken');

    if (repoPath != null || remoteUrl != null) {
      _gitConfig = GitConfig(
        repoPath: repoPath,
        remoteUrl: remoteUrl,
        branch: branch,
        username: username,
        email: email,
        accessToken: accessToken,
      );
    }
  }

  Future<void> setGitConfig(GitConfig config) async {
    _gitConfig = config;
    if (config.repoPath != null) {
      await _prefs?.setString('gitRepoPath', config.repoPath!);
    }
    if (config.remoteUrl != null) {
      await _prefs?.setString('gitRemoteUrl', config.remoteUrl!);
    }
    if (config.branch != null) {
      await _prefs?.setString('gitBranch', config.branch!);
    }
    if (config.username != null) {
      await _prefs?.setString('gitUsername', config.username!);
    }
    if (config.email != null) {
      await _prefs?.setString('gitEmail', config.email!);
    }
    if (config.accessToken != null) {
      await _prefs?.setString('gitAccessToken', config.accessToken!);
    }
    notifyListeners();
  }

  void setCurrentPost(BlogPost? post) {
    _currentPost = post;
    notifyListeners();
  }

  void setPosts(List<BlogPost> posts) {
    _posts = posts;
    notifyListeners();
  }

  void addPost(BlogPost post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void updatePost(BlogPost post) {
    final index = _posts.indexWhere((p) => p.filePath == post.filePath);
    if (index != -1) {
      _posts[index] = post;
      notifyListeners();
    }
  }

  void removePost(String filePath) {
    _posts.removeWhere((p) => p.filePath == filePath);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

