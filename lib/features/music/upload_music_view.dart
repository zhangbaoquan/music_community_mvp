import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'music_controller.dart';

class UploadMusicView extends StatefulWidget {
  const UploadMusicView({super.key});

  @override
  State<UploadMusicView> createState() => _UploadMusicViewState();
}

class _UploadMusicViewState extends State<UploadMusicView> {
  final _controller = Get.put(MusicController());

  final _titleController = TextEditingController();
  final _artistController = TextEditingController();

  PlatformFile? _audioFile;
  XFile? _coverFile;
  final List<String> _selectedMoods = [];

  final List<String> _availableMoods = [
    '快乐 (Happy)',
    '伤感 (Sad)',
    '平静 (Calm)',
    '活力 (Energetic)',
    '专注 (Focus)',
    '助眠 (Sleep)',
    '浪漫 (Romance)',
    '忧郁 (Melancholy)',
  ];

  Future<void> _pickAudio() async {
    try {
      print("Starting file picker...");
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        print("File picked: ${result.files.first.name}");
        setState(() {
          _audioFile = result.files.first;
        });
      } else {
        print("File picker canceled.");
      }
    } catch (e) {
      print("Error picking file: $e");
      Get.snackbar('错误', '无法打开文件选择器: $e');
    }
  }

  Future<void> _pickCover() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _coverFile = image;
      });
    }
  }

  void _submit() async {
    if (_audioFile == null) {
      Get.snackbar('提示', '请选择音频文件');
      return;
    }
    if (_titleController.text.isEmpty) {
      Get.snackbar('提示', '请输入歌曲标题');
      return;
    }

    final success = await _controller.uploadSong(
      audioFile: _audioFile!,
      title: _titleController.text,
      artist: _artistController.text,
      coverFile: _coverFile,
      moodTags: _selectedMoods,
    );

    if (success) {
      setState(() {
        _audioFile = null;
        _coverFile = null;
        _titleController.clear();
        _artistController.clear();
        _selectedMoods.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发布原创音乐'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Audio File Picker
            Material(
              color: Colors.grey[50], // Background color
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _pickAudio,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _audioFile == null
                            ? Icons.cloud_upload_outlined
                            : Icons.audio_file,
                        size: 48,
                        color: _audioFile == null
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _audioFile == null
                            ? '点击上传音频 (MP3/WAV/FLAC)'
                            : _audioFile!.name,
                        style: TextStyle(
                          color: _audioFile == null
                              ? Colors.grey[600]
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_audioFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '大小: ${(_audioFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Cover Image & Metadata
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image
                GestureDetector(
                  onTap: _pickCover,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                      image: _coverFile != null
                          ? DecorationImage(
                              image: NetworkImage(_coverFile!.path),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _coverFile == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.grey),
                                SizedBox(height: 4),
                                Text(
                                  "封面",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),

                // Fields
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '歌曲标题',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _artistController,
                        decoration: const InputDecoration(
                          labelText: '歌手名称 (选填)',
                          hintText: '默认为当前用户名',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Mood Tags
            const Text(
              '选择心情标签',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableMoods.map((mood) {
                final isSelected = _selectedMoods.contains(mood);
                return ChoiceChip(
                  label: Text(mood),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (_selectedMoods.length < 3) {
                          _selectedMoods.add(mood);
                        } else {
                          Get.snackbar('提示', '最多选择3个标签');
                        }
                      } else {
                        _selectedMoods.remove(mood);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // 4. Submit Button
            Obx(() {
              final isUploading = _controller.isUploading.value;
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('正在上传...'),
                          ],
                        )
                      : const Text(
                          '立即发布',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
