import 'package:camera/camera.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
  //  show newTextPrimary, newTextSecondary, newBorderColor, newBlueColor, newBlueLightColor, newRedColor;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'dart:io';

class FileAttachmentWidget extends StatefulWidget {
  final String label;
  final List<PlatformFile> selectedFiles;
  final Function(List<PlatformFile>) onFilesSelected;

  const FileAttachmentWidget({
    Key? key,
    required this.label,
    required this.selectedFiles,
    required this.onFilesSelected,
  }) : super(key: key);

  @override
  State<FileAttachmentWidget> createState() => _FileAttachmentWidgetState();
}

class _FileAttachmentWidgetState extends State<FileAttachmentWidget> {
  Future<void> _showPickOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: newBlueColor),
                title: const Text("Select from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: newBlueColor),
                title: const Text("Take Photo from Camera"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _pickFromGallery() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      final newFiles = List<PlatformFile>.from(widget.selectedFiles)
        ..addAll(result.files);

      widget.onFilesSelected(newFiles);
    }
  }

  Future<void> _pickFromCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    final XFile? photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraCaptureScreen(camera: camera),
      ),
    );

    if (photo != null) {
      final file = File(photo.path);

      final newFiles = List<PlatformFile>.from(widget.selectedFiles)
        ..add(
          PlatformFile(
            name: photo.name,
            path: photo.path,
            size: await file.length(),
          ),
        );

      widget.onFilesSelected(newFiles);
    }
  }

  void _removeFile(int index) {
    final updatedFiles = List<PlatformFile>.from(widget.selectedFiles)
      ..removeAt(index);

    widget.onFilesSelected(updatedFiles);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: newTextPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: newBorderColor),
            color: Colors.white,
          ),
          child: Column(
            children: [
              InkWell(
                onTap: _showPickOptions,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: newBlueLightColor,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          color: newBlueColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Click to browse or capture',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: newBlueColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select from Gallery or Camera',
                        style: TextStyle(fontSize: 12, color: newTextSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.selectedFiles.isNotEmpty) ...[
                const Divider(height: 1),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = widget.selectedFiles[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: newBlueLightColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.insert_drive_file_outlined,
                              color: newBlueColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: newTextPrimary),
                                ),
                                Text(
                                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(fontSize: 12, color: newTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeFile(index),
                            icon: Icon(
                              Icons.close_rounded,
                              color: newRedColor,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class CameraCaptureScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraCaptureScreen({super.key, required this.camera});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  late CameraController _controller;
  late Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Photo')),
      body: FutureBuilder(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final photo = await _controller.takePicture();
          Navigator.pop(context, photo);
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
