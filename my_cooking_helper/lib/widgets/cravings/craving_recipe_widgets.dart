// lib/features/cravings/craving_recipe_widgets.dart
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/models/cravings.dart';
import '/utils/colors.dart';

/// -------------------------------
/// Glass primitives
/// -------------------------------
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.blur = 14,
    this.opacity = 0.08,
    this.strokeOpacity = 0.20,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final double strokeOpacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stroke = isDark ? Colors.white : Colors.black;
    final glassColor = isDark ? Colors.white : Colors.black;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: glassColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius.r),
            border: Border.all(color: stroke.withOpacity(strokeOpacity)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassSection extends StatelessWidget {
  const GlassSection({
    super.key,
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor(context),
                    ),
              ),
              SizedBox(height: 8.h),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class GlassHeroImage extends StatelessWidget {
  const GlassHeroImage({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 20,
      blur: 18,
      opacity: 0.06,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// -------------------------------
/// Typographic helpers
/// -------------------------------
class SubHeader extends StatelessWidget {
  const SubHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor(context),
          ),
    );
  }
}

class BulletLine extends StatelessWidget {
  const BulletLine({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(color: textColor(context))),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor(context).withOpacity(0.96),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------------------
/// Chips & Tags
/// -------------------------------
class TinyChip extends StatelessWidget {
  const TinyChip({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 12,
      opacity: 0.06,
      strokeOpacity: 0.12,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: textColor(context)),
            SizedBox(width: 6.w),
            Text(text, style: TextStyle(color: textColor(context))),
          ],
        ),
      ),
    );
  }
}

class PillTag extends StatelessWidget {
  const PillTag({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 999,
      opacity: 0.07,
      strokeOpacity: 0.10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Text(text, style: TextStyle(fontSize: 12.sp, color: textColor(context))),
      ),
    );
  }
}

class FlagTag extends StatelessWidget {
  const FlagTag({super.key, required this.text, required this.emoji});
  final String text;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 999,
      opacity: 0.07,
      strokeOpacity: 0.10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 14.sp)),
            SizedBox(width: 6.w),
            Text(text, style: TextStyle(fontSize: 12.sp, color: textColor(context))),
          ],
        ),
      ),
    );
  }
}

/// -------------------------------
/// Detail tiles
/// -------------------------------
class IngredientTile extends StatelessWidget {
  const IngredientTile({super.key, required this.data});
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    String label;
    if (data is String) {
      label = data;
    } else if (data is Map) {
      final name = (data['name'] ?? '').toString();
      final q = (data['quantity'] as num?)?.toDouble();
      final unit = (data['unit'] ?? '').toString();
      if (q == null || q == 0) {
        label = name;
      } else {
        final qStr = q % 1 == 0 ? q.toStringAsFixed(0) : q.toString();
        label = unit.isEmpty ? "$name — $qStr" : "$name — $qStr $unit";
      }
    } else {
      label = data.toString();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(Icons.checklist_rounded, size: 16.sp, color: textColor(context).withOpacity(0.85)),
          SizedBox(width: 8.w),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class InstructionTile extends StatelessWidget {
  const InstructionTile({super.key, required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$index. ", style: TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class ShoppingTile extends StatelessWidget {
  const ShoppingTile({super.key, required this.item});
  final ShoppingItemModel item;

  @override
  Widget build(BuildContext context) {
    final need = item.need.toStringAsFixed(item.need % 1 == 0 ? 0 : 1);
    final have = item.have.toStringAsFixed(item.have % 1 == 0 ? 0 : 1);
    final tagColor = item.tag == 'missing'
        ? Colors.amber[700]
        : Theme.of(context).colorScheme.tertiary;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(Icons.shopping_cart_checkout_rounded,
              size: 18.sp, color: textColor(context).withOpacity(0.9)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text("${item.name} • $need ${item.unit}  —  have: $have ${item.unit}"),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: (tagColor ?? Colors.grey).withOpacity(0.15),
              border: Border.all(color: tagColor ?? Colors.grey),
            ),
            child: Text(
              item.tag,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------------------
/// AI caution footer
/// -------------------------------
class AiCautionBar extends StatelessWidget {
  const AiCautionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 14,
      opacity: 0.06,
      strokeOpacity: 0.10,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18.sp, color: textColor(context).withOpacity(0.9)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "These recipes are AI-generated. Validate quantities to your taste and check for allergens before cooking.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor(context).withOpacity(0.9),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------------------
/// Cuisine → emoji mapping
/// -------------------------------
String cuisineFlagEmoji(String name) {
  final key = name.trim().toLowerCase();
  const map = {
    'italian': '🍝',
    'asian': '🥢',
    'caribbean': '🍍',
    'eastern european': '🥟',
    'european': '🍽️',
    'irish': '🍀',
    'latin american': '🌯',
    'chinese': '🥡',
    'mexican': '🌮',
    'indian': '🍛',
    'japanese': '🍣',
    'thai': '🍜',
    'korean': '🍲',
    'vietnamese': '🥢',
    'spanish': '🥘',
    'french': '🥖',
    'middle eastern': '🥙',
    'mediterranean': '🥗',
    'american': '🍔',
    'british': '🥧',
    'greek': '🥙',
    'german': '🥨',
    'mauritian': '🍲',
    'other': '🌍',
  };
  return map[key] ?? '🌍';
}
