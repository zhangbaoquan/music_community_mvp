// 标准图片嵌入构建器 — Quill 编辑器中图片的自定义渲染
//
// 功能：
// - 支持图片选中高亮（蓝色边框）
// - 支持拖拽调整图片宽度（通过 tempWidth 参数）
// - 支持图片对齐方式（左/中/右）
// - 兼容直接属性和 CSS style 属性中的尺寸信息
//
// 从 [StoryEditorView] 拆出的独立组件。
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';


/// Quill 图片嵌入构建器
///
/// [selectedNode] 当前选中的图片节点（用于高亮边框）
/// [tempWidth] 拖拽调整大小时的临时宽度（滑块拖拽中）
class StandardImageEmbedBuilder extends EmbedBuilder {
  final Node? selectedNode;
  final double? tempWidth;

  StandardImageEmbedBuilder({this.selectedNode, this.tempWidth});

  @override
  String get key => 'image';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    // 获取图片 URL
    String imageUrl = "";
    if (embedContext.node.value.data is String) {
      imageUrl = embedContext.node.value.data as String;
    }

    if (imageUrl.isEmpty) return const SizedBox();

    // 从属性中解析宽高
    double? width;
    double? height;
    final style = embedContext.node.style;
    final attrs = style.attributes;

    if (attrs.containsKey('width')) {
      final w = attrs['width']?.value;
      if (w != null) width = double.tryParse(w.toString());
    }

    final isSelected = selectedNode == embedContext.node;

    // 拖拽中使用临时宽度
    if (isSelected && tempWidth != null) {
      width = tempWidth;
    }

    return GestureDetector(
      onTap: () {
        // 点击图片时选中它
        final offset = embedContext.node.documentOffset;
        embedContext.controller.updateSelection(
          TextSelection.collapsed(offset: offset),
          ChangeSource.local,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: _getAlignment(style),
        child: IntrinsicWidth(
          child: Container(
            // 选中时显示蓝色边框
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 3,
                    ),
                  )
                : null,
            child: Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.contain,
              // 图片加载失败时显示占位
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                width: width ?? 300,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
              // 图片加载中显示进度
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  width: width ?? 300,
                  color: Colors.grey[100],
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 根据样式属性获取对齐方式
  AlignmentGeometry _getAlignment(Style style) {
    if (style.attributes.containsKey('align')) {
      final val = style.attributes['align']?.value;
      if (val == 'center') return Alignment.center;
      if (val == 'right') return Alignment.centerRight;
      if (val == 'left') return Alignment.centerLeft;
    }
    return Alignment.center;
  }
}
