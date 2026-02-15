import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class ArticleImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    // Extract properties from EmbedContext
    final controller = embedContext.controller;
    final node = embedContext.node;
    final readOnly = embedContext.readOnly;
    // final inline = embedContext.inline; // Unused
    // final textStyle = embedContext.textStyle; // Unused

    final imageUrl = node.value.data as String;
    final attributes = node.style.attributes;
    final widthAttribute = attributes['width']; // Restore this line
    // final alignAttribute = attributes['align']; // Removed unused variable

    // Parse width for display (pixels)
    final width = _parseWidth(attributes, context);

    // Old manual parsing logic removed in favor of _parseWidth
    /*
    double? width;
    if (widthAttribute != null) {
      if (widthAttribute.value is String) {
        if (widthAttribute.value.endsWith('%')) {
          // Handle percentage (approximate for display)
          final percent = double.tryParse(
            widthAttribute.value.replaceAll('%', ''),
          );
          if (percent != null) {
            // Calculate width based on screen width
            width = MediaQuery.of(context).size.width * (percent / 100);
          }
        } else {
          width = double.tryParse(widthAttribute.value);
        }
      } else if (widthAttribute.value is num) {
        width = (widthAttribute.value as num).toDouble();
      }
    }
    */

    // Force center alignment for all images
    AlignmentGeometry alignment = Alignment.center;

    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width ?? 300,
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          constraints: const BoxConstraints(minHeight: 100),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );

    // Apply alignment
    imageWidget = Align(alignment: alignment, child: imageWidget);

    if (readOnly) return imageWidget;

    return GestureDetector(
      onTap: () {
        // Resolve current width value string (e.g. "50%")
        // Check standard 'width' attribute first, then 'style' attribute
        String? currentWidthString = widthAttribute?.value?.toString();
        if (currentWidthString == null && attributes.containsKey('style')) {
          final styleMap = _parseStyleString(
            attributes['style']!.value.toString(),
          );
          currentWidthString = styleMap['width'];
        }

        _showImageSettings(context, controller, node, currentWidthString);
      },
      child: imageWidget,
    );
  }

  void _showImageSettings(
    BuildContext context,
    QuillController controller,
    Embed node,
    String? currentWidth,
  ) {
    // Initial values
    double currentScale = 1.0;
    if (currentWidth != null && currentWidth.endsWith('%')) {
      currentScale =
          (double.tryParse(currentWidth.replaceAll('%', '')) ?? 100) / 100;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.transparent, // Allow seeing the image clearly
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '图片设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Label for Scale
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('缩放大小', style: TextStyle(fontSize: 14)),
                      Text(
                        '${(currentScale * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: currentScale,
                    min: 0.1,
                    max: 1.0,
                    divisions: 18, // 5% increments
                    label: '${(currentScale * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() {
                        currentScale = value;
                      });
                      // Update in real-time
                      _updateAttribute(
                        controller,
                        node,
                        Attribute.clone(
                          Attribute.width,
                          "${(value * 100).toInt()}%",
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // This method is no longer used due to forced center alignment and UI removal.
  // It can be removed if not used elsewhere.
  /*
  Widget _buildAlignOption(
    String value,
    IconData icon,
    String current,
    Function(String) onTap,
  ) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[600]),
      ),
    );
  }
  */

  void _updateAttribute(
    QuillController controller,
    Embed node,
    Attribute attribute,
  ) {
    final offset = _findNodeOffset(controller.document, node);
    // print("ArticleImageEmbedBuilder: Updating attribute. Node: ${node.value.data}, Attr: ${attribute.key}=${attribute.value}, Offset found: $offset");
    if (offset != -1) {
      try {
        // 1. Try standard Attribute (width or align)
        // Use attribute.clone to ensure we create a fresh one correctly
        // If key is width, we try standard width.
        controller.formatText(offset, 1, attribute);
      } catch (e) {
        // print("ArticleImageEmbedBuilder: formatText failed with standard attribute: $e");
        // 2. Fallback: If width fails, try passing as 'style' attribute (CSS-like) which is often more permissible for inline/web
        if (attribute.key == 'width') {
          try {
            // Construct style attribute manually: "width: 90%"
            final styleAttr = Attribute(
              'style',
              AttributeScope.ignore,
              'width: ${attribute.value}',
            );
            controller.formatText(offset, 1, styleAttr);
            // print("ArticleImageEmbedBuilder: Fallback to style attribute successful.");
          } catch (e2) {
            // print("ArticleImageEmbedBuilder: Fallback to style attribute also failed: $e2");
          }
        }
      }
    } else {
      // print("ArticleImageEmbedBuilder: Node not found in document!");
    }
  }

  // Update parsing logic in build to extract width from style if needed
  double? _parseWidth(Map<String, Attribute> attributes, BuildContext context) {
    Attribute? widthAttribute = attributes['width'];

    // If width attribute is missing, check 'style' attribute
    if (widthAttribute == null && attributes.containsKey('style')) {
      final style = attributes['style']!.value.toString();
      // Parse "width: 80%" or similar from style string
      final styleMap = _parseStyleString(style);
      if (styleMap.containsKey('width')) {
        // Create a temporary attribute to reuse logic
        widthAttribute = Attribute(
          'width',
          AttributeScope.ignore,
          styleMap['width'],
        );
      }
    }

    if (widthAttribute != null) {
      if (widthAttribute.value is String) {
        if (widthAttribute.value.endsWith('%')) {
          final percent = double.tryParse(
            widthAttribute.value.replaceAll('%', ''),
          );
          if (percent != null) {
            return MediaQuery.of(context).size.width * (percent / 100);
          }
        } else {
          return double.tryParse(widthAttribute.value);
        }
      } else if (widthAttribute.value is num) {
        return (widthAttribute.value as num).toDouble();
      }
    }
    return null;
  }

  Map<String, String> _parseStyleString(String style) {
    final map = <String, String>{};
    for (final pair in style.split(';')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[parts[0].trim()] = parts[1].trim();
      }
    }
    return map;
  }

  int _findNodeOffset(Document document, Embed node) {
    int offset = 0;
    final targetData = node.value.data;
    for (final op in document.toDelta().toList()) {
      final len = op.length;
      if (op.data is Map) {
        final dataMap = op.data as Map;
        if (dataMap.containsKey(BlockEmbed.imageType)) {
          final url = dataMap[BlockEmbed.imageType];
          // print("ArticleImageEmbedBuilder: Checking Op at $offset. URL: $url vs Target: $targetData");
          if (url == targetData) {
            return offset;
          }
        }
      }
      offset += (len ?? 0);
    }
    return -1;
  }
}
