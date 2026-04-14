/// 文章编辑器标签选择器 — 管理文章的自定义标签
///
/// 支持预定义标签快速选择和手动输入自定义标签。
/// 从 [ArticleEditorView] 拆出的独立组件。
import 'package:flutter/material.dart';

/// 标签选择器组件
///
/// [primaryColor] 主题色
/// [selectedTags] 已选标签列表（可变引用，直接修改）
/// [tagController] 自定义标签输入框控制器
/// [onTagsChanged] 标签变化后的回调（触发父组件 setState）
class EditorTagSelector extends StatelessWidget {
  final Color primaryColor;
  final List<String> selectedTags;
  final TextEditingController tagController;
  final VoidCallback onTagsChanged;

  /// 预定义标签列表
  static const List<String> _predefinedTags = ["成长", "音乐故事", "情感", "生活"];

  const EditorTagSelector({
    super.key,
    required this.primaryColor,
    required this.selectedTags,
    required this.tagController,
    required this.onTagsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 段落标题
        Row(
          children: [
            Container(
              width: 4, height: 16,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "标签 (Tags)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 已选标签（可删除）
            ...selectedTags.map((tag) => _buildSelectedTag(tag)),
            // 未选的预定义标签（可添加）
            ..._predefinedTags
                .where((t) => !selectedTags.contains(t))
                .map((t) => _buildPredefinedTag(t)),
            // 自定义标签输入框
            _buildCustomTagInput(),
          ],
        ),
      ],
    );
  }

  /// 已选标签 Chip（带删除按钮）
  Widget _buildSelectedTag(String tag) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              color: primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              selectedTags.remove(tag);
              onTagsChanged();
            },
            child: Icon(Icons.close, size: 16, color: primaryColor),
          ),
        ],
      ),
    );
  }

  /// 预定义标签（点击添加）
  Widget _buildPredefinedTag(String tag) {
    return GestureDetector(
      onTap: () {
        selectedTags.add(tag);
        onTagsChanged();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          tag,
          style: TextStyle(color: Colors.grey[700], fontSize: 13),
        ),
      ),
    );
  }

  /// 自定义标签输入框
  Widget _buildCustomTagInput() {
    return Container(
      width: 100,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.add, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: tagController,
              decoration: const InputDecoration(
                hintText: '自定义',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty &&
                    !selectedTags.contains(value.trim())) {
                  selectedTags.add(value.trim());
                  tagController.clear();
                  onTagsChanged();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
