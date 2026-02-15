
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'package:path/path.dart' as path;
import '../models/hexo_config.dart';

class YamlService {
  Future<HexoConfig?> loadHexoConfig(String blogPath) async {
    final configPath = path.join(blogPath, '_config.yml');
    final file = File(configPath);
    
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final yamlMap = loadYaml(content) as Map?;
      
      if (yamlMap == null) {
        return HexoConfig();
      }

      final map = Map<String, dynamic>.from(yamlMap);
      return HexoConfig.fromMap(map);
    } catch (e) {
      print('Error loading config: $e');
      return null;
    }
  }

  Future<void> saveHexoConfig(String blogPath, HexoConfig config) async {
    final configPath = path.join(blogPath, '_config.yml');
    final map = config.toMap();
    
    final writer = YamlWriter();
    final yamlContent = writer.write(map);
    
    final file = File(configPath);
    await file.writeAsString(yamlContent);
  }

  Future<Map<String, dynamic>?> loadThemeConfig(String blogPath, String theme) async {
    final configPath = path.join(blogPath, '_config.$theme.yml');
    final file = File(configPath);
    
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final yamlMap = loadYaml(content) as Map?;
      
      if (yamlMap == null) {
        return {};
      }

      return Map<String, dynamic>.from(yamlMap);
    } catch (e) {
      print('Error loading theme config: $e');
      return null;
    }
  }

  Future<void> saveThemeConfig(String blogPath, String theme, Map<String, dynamic> config) async {
    final configPath = path.join(blogPath, '_config.$theme.yml');
    final writer = YamlWriter();
    final yamlContent = writer.write(config);
    
    final file = File(configPath);
    await file.writeAsString(yamlContent);
  }

  Future<void> backupConfig(String configPath) async {
    final file = File(configPath);
    if (await file.exists()) {
      final backupPath = '$configPath.backup.${DateTime.now().millisecondsSinceEpoch}';
      await file.copy(backupPath);
    }
  }

  Future<void> restoreConfig(String backupPath, String configPath) async {
    final backupFile = File(backupPath);
    if (await backupFile.exists()) {
      await backupFile.copy(configPath);
    }
  }
}
