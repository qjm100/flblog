import 'dart:io';
import 'package:path/path.dart' as path;

class GitService {
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
    try {
      await _runGitCommand(repoPath, ['rev-parse', '--is-inside-work-tree']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> initRepo(String repoPath) async {
    final result = await _runGitCommand(repoPath, ['init']);
    return result.stdout.toString().trim();
  }

  Future<String> setRemote(String repoPath, String remoteUrl) async {
    try {
      await _runGitCommand(repoPath, ['remote', 'remove', 'origin']);
    } catch (e) {
    }

    final result = await _runGitCommand(repoPath, ['remote', 'add', 'origin', remoteUrl]);
    return result.stdout.toString().trim();
  }

  Future<String?> getCurrentBranch(String repoPath) async {
    try {
      final result = await _runGitCommand(repoPath, ['branch', '--show-current']);
      return result.stdout.toString().trim();
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getBranches(String repoPath) async {
    try {
      final result = await _runGitCommand(repoPath, ['branch', '-a']);
      final branches = result.stdout.toString()
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
    final result = await _runGitCommand(repoPath, ['checkout', branch]);
    return result.stdout.toString().trim();
  }

  Future<String> createBranch(String repoPath, String branch) async {
    final result = await _runGitCommand(repoPath, ['checkout', '-b', branch]);
    return result.stdout.toString().trim();
  }

  Future<String> addAll(String repoPath) async {
    final result = await _runGitCommand(repoPath, ['add', '.']);
    return result.stdout.toString().trim();
  }

  Future<String> add(String repoPath, List<String> files) async {
    final result = await _runGitCommand(repoPath, ['add', ...files]);
    return result.stdout.toString().trim();
  }

  Future<String> commit(String repoPath, String message) async {
    final result = await _runGitCommand(repoPath, ['commit', '-m', message]);
    return result.stdout.toString().trim();
  }

  Future<String> pull(String repoPath, {String? branch}) async {
    final args = branch != null ? ['pull', 'origin', branch] : ['pull'];
    final result = await _runGitCommand(repoPath, args);
    return result.stdout.toString().trim();
  }

  Future<String> push(String repoPath, {String? branch, bool setUpstream = false}) async {
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
    try {
      final result = await _runGitCommand(repoPath, ['status']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> getLog(String repoPath, {int limit = 10}) async {
    try {
      final result = await _runGitCommand(repoPath, ['log', '--oneline', '-$limit']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> setUserConfig(String repoPath, String name, String email) async {
    await _runGitCommand(repoPath, ['config', 'user.name', name]);
    final result = await _runGitCommand(repoPath, ['config', 'user.email', email]);
    return result.stdout.toString().trim();
  }

  Future<bool> hasUncommittedChanges(String repoPath) async {
    try {
      final result = await _runGitCommand(repoPath, ['status', '--porcelain']);
      return result.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
