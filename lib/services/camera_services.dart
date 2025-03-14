import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();
  
  // Chiedi i permessi della fotocamera e della galleria
  Future<bool> requestCameraPermissions() async {
    var cameraStatus = await Permission.camera.status;
    var photosStatus = await Permission.photos.status;
    
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }
    
    if (!photosStatus.isGranted) {
      photosStatus = await Permission.photos.request();
    }
    
    return cameraStatus.isGranted && photosStatus.isGranted;
  }
  
  // Cattura una foto dalla fotocamera
  Future<File?> takePhoto({bool compress = true}) async {
    if (!await requestCameraPermissions()) {
      return null;
    }
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (image == null) return null;
    
    if (compress) {
      return await compressImage(File(image.path));
    }
    
    return File(image.path);
  }
  
  // Seleziona una foto dalla galleria
  Future<File?> pickImageFromGallery({bool compress = true}) async {
    if (!await requestCameraPermissions()) {
      return null;
    }
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (image == null) return null;
    
    if (compress) {
      return await compressImage(File(image.path));
    }
    
    return File(image.path);
  }
  
  // Comprime l'immagine per ridurre lo spazio di archiviazione
  Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      var compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 80,
        minWidth: 1000,
        minHeight: 1000,
      );
      
      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Ritorna l'immagine originale in caso di errore
    }
  }
  
  // Salva l'immagine in una posizione permanente
  Future<File?> saveImagePermanently(File tempFile, String filename) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final extension = path.extension(tempFile.path);
      final targetPath = '${imagesDir.path}/$filename$extension';
      
      return await tempFile.copy(targetPath);
    } catch (e) {
      print('Error saving image permanently: $e');
      return null;
    }
  }
}