import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestStoragePermission() async {
    if (kIsWeb) {
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status.isGranted) {
        return true;
      }

      final result = await Permission.storage.request();
      if (result.isGranted) {
        return true;
      }

      if (result.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }

    return true;
  }

  Future<bool> requestManageExternalStorage() async {
    if (kIsWeb) {
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) {
        return true;
      }

      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) {
        return true;
      }

      if (result.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return false;
    }

    return true;
  }

  Future<bool> checkAndRequestPermissions() async {
    if (kIsWeb) {
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      bool hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        return false;
      }

      hasPermission = await requestManageExternalStorage();
      return hasPermission;
    }

    return true;
  }
}
