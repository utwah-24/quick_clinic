import 'package:flutter/material.dart';

class DynamicAppBar extends StatelessWidget {
  final Widget? leading;
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Color titleColor;
  final Color? backgroundColor;
  final Color? iconColor;
  final EdgeInsets? padding;

  const DynamicAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed, 
    this.leading,
    this.titleColor = Colors.black,
    this.backgroundColor,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Use explicit iconColor if provided, otherwise determine based on background color
    final Color finalIconColor = iconColor ?? 
        (backgroundColor != null ? Colors.white : const Color(0xFF1565C0));
    
    final EdgeInsets resolvedPadding = padding ?? EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 30,
      left: 16,
      right: 16,
      bottom: 16,
    );

    return Container(
      color: backgroundColor, // Apply background color to the container
      padding: resolvedPadding,
      child: Row(
        children: [
          // Drawer button
          IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: Icon(
              Icons.menu,
              color: finalIconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 10),
          ],
          if (onBackPressed != null) ...[
            IconButton(
              onPressed: onBackPressed,
              icon: Icon(
                Icons.arrow_back_ios,
                color: finalIconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                // fontFamily: 'sans',
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: titleColor,
                letterSpacing: -0.3,
                height: 1.0,
              ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
