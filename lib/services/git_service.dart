import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'github_api_service.dart';

class GitService {
  final GitHubApiService? _apiService;

  GitService({GitHubApiService? apiService}) : _apiService = apiService;

  bool get _useApi =>
      !Platform.isLinux && !Platform.isWindows && !Platform.isMacOS;

  bool _isValidPath(String repoPath) {
    if (repoPath.isEmpty) return false;
    final dir = Directory(repoPath);
    return dir.existsSync();
  }

  Future<ProcessResult> _runGitCommand(
    String repoPath,
    List<String> arguments,
  ) async {
    if (!_isValidPath(repoPath)) {
      throw Exception('仓库路径无效或不存在');
    }

    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: repoPath,
    );

    if (result.exitCode != 0) {
      final error = result.stderr.toString().trim();
      final output = result.stdout.toString().trim();
      throw Exception(
        error.isNotEmpty ? error : (output.isNotEmpty ? output : 'Git命令执行失败'),
      );
    }

    return result;
  }

  Future<bool> isGitRepo(String repoPath) async {
    if (_useApi) {
      return true;
    }
    try {
      await _runGitCommand(repoPath, ['rev-parse', '--is-inside-work-tree']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> initRepo(String repoPath) async {
    if (_useApi) {
      throw Exception('移动端不支持初始化仓库，请使用已有的GitHub仓库');
    }
    final result = await _runGitCommand(repoPath, ['init']);
    return result.stdout.toString().trim();
  }

  Future<String> setRemote(String repoPath, String remoteUrl) async {
    if (_useApi) {
      return '已设置远程仓库: $remoteUrl';
    }
    try {
      await _runGitCommand(repoPath, ['remote', 'remove', 'origin']);
    } catch (e) {}

    final result =
        await _runGitCommand(repoPath, ['remote', 'add', 'origin', remoteUrl]);
    return result.stdout.toString().trim();
  }

  Future<String?> getCurrentBranch(String repoPath) async {
    if (_useApi && _apiService != null) {
      try {
        return await _apiService!.getDefaultBranch(repoPath);
      } catch (e) {
        return null;
      }
    }
    try {
      final result =
          await _runGitCommand(repoPath, ['branch', '--show-current']);
      return result.stdout.toString().trim();
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getBranches(String repoPath) async {
    if (_useApi && _apiService != null) {
      try {
        return await _apiService!.getBranches(repoPath);
      } catch (e) {
        return [];
      }
    }
    try {
      final result = await _runGitCommand(repoPath, ['branch', '-a']);
      final branches = result.stdout
          .toString()
          .split('\n')
          .map((b) => b.trim().replaceAll('* ', ''))
          .where((b) => b.isNotEmpty)
          .toList();
      return branches;
    } catch (e) {
      return [];
    }
  }

  Future<String> checkoutBranch(String repoPath, String branch) async {
    if (_useApi) {
      throw Exception('移动端不支持切换分支，请使用GitHub网页操作');
    }
    final result = await _runGitCommand(repoPath, ['checkout', branch]);
    return result.stdout.toString().trim();
  }

  Future<String> createBranch(String repoPath, String branch) async {
    if (_useApi && _apiService != null) {
      try {
        final defaultBranch = await _apiService!.getDefaultBranch(repoPath);
        await _apiService!.createBranch(
          remoteUrl: repoPath,
          newBranch: branch,
          fromBranch: defaultBranch,
        );
        return '已创建分支: $branch';
      } catch (e) {
        throw Exception('创建分支失败: $e');
      }
    }
    final result = await _runGitCommand(repoPath, ['checkout', '-b', branch]);
    return result.stdout.toString().trim();
  }

  Future<String> addAll(String repoPath) async {
    if (_useApi) {
      throw Exception('移动端不支持此操作');
    }
    final result = await _runGitCommand(repoPath, ['add', '.']);
    return result.stdout.toString().trim();
  }

  Future<String> add(String repoPath, List<String> files) async {
    if (_useApi) {
      throw Exception('移动端不支持此操作');
    }
    final result = await _runGitCommand(repoPath, ['add', ...files]);
    return result.stdout.toString().trim();
  }

  Future<String> commit(String repoPath, String message) async {
    if (_useApi) {
      throw Exception('移动端不支持此操作');
    }
    final result = await _runGitCommand(repoPath, ['commit', '-m', message]);
    return result.stdout.toString().trim();
  }

  Future<String> pull(String repoPath, {String? branch}) async {
    if (_useApi) {
      throw Exception('移动端不支持pull操作，请使用同步功能');
    }
    final args = branch != null ? ['pull', 'origin', branch] : ['pull'];
    final result = await _runGitCommand(repoPath, args);
    return result.stdout.toString().trim();
  }

  Future<String> push(String repoPath,
      {String? branch, bool setUpstream = false}) async {
    if (_useApi) {
      throw Exception('移动端不支持push操作，请使用同步功能');
    }
    List<String> args = ['push'];
    if (branch != null) {
      if (setUpstream) {
        args = ['push', '-u', 'origin', branch];
      } else {
        args = ['push', 'origin', branch];
      }
    }
    final result = await _runGitCommand(repoPath, args);
    return result.stdout.toString().trim();
  }

  Future<String> getStatus(String repoPath) async {
    if (_useApi) {
      return '移动端使用GitHub API模式';
    }
    try {
      final result = await _runGitCommand(repoPath, ['status']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> getLog(String repoPath, {int limit = 10}) async {
    if (_useApi && _apiService != null) {
      try {
        final commits = await _apiService!.getCommits(repoPath, perPage: limit);
        return commits.map((c) {
          final sha = (c['sha'] as String).substring(0, 7);
          final message = c['commit']['message'] as String;
          return '$sha $message';
        }).join('\n');
      } catch (e) {
        return 'Error: $e';
      }
    }
    try {
      final result =
          await _runGitCommand(repoPath, ['log', '--oneline', '-$limit']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> setUserConfig(
      String repoPath, String name, String email) async {
    if (_useApi) {
      return 'API模式不需要配置用户信息';
    }
    await _runGitCommand(repoPath, ['config', 'user.name', name]);
    final result =
        await _runGitCommand(repoPath, ['config', 'user.email', email]);
    return result.stdout.toString().trim();
  }

  Future<bool> hasUncommittedChanges(String repoPath) async {
    if (_useApi) {
      return false;
    }
    try {
      final result = await _runGitCommand(repoPath, ['status', '--porcelain']);
      return result.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String> syncFile({
    required String remoteUrl,
    required String localPath,
    required String relativePath,
    required String message,
    String branch = 'main',
  }) async {
    if (_apiService == null) {
      throw Exception('未配置GitHub Access Token');
    }

    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $localPath');
    }

    final content = await file.readAsString();
    String? sha;

    try {
      final existingFile = await _apiService!.getFileContent(
        remoteUrl,
        relativePath,
        branch: branch,
      );
      sha = existingFile['sha'] as String?;
    } catch (e) {}

    await _apiService!.createOrUpdateFile(
      remoteUrl: remoteUrl,
      path: relativePath,
      content: content,
      message: message,
      sha: sha,
      branch: branch,
    );

    return '文件已同步到GitHub';
  }

  Future<String> downloadFile({
    required String remoteUrl,
    required String localPath,
    required String relativePath,
    String branch = 'main',
  }) async {
    if (_apiService == null) {
      throw Exception('未配置GitHub Access Token');
    }

    final fileData = await _apiService!.getFileContent(
      remoteUrl,
      relativePath,
      branch: branch,
    );

    final content = fileData['content'] as String;
    final decoded = utf8.decode(base64Decode(content.replaceAll('\n', '')));

    final file = File(localPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(decoded);

    return '文件已从GitHub下载';
  }

  bool get isApiMode => _useApi;
}
