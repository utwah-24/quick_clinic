import 'package:flutter/material.dart';

class DynamicAppBar extends StatelessWidget {
  final Widget? leading;
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Color titleColor;

  const DynamicAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed, this.leading,
    this.titleColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 30,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 10),
          ],
          if (onBackPressed != null) ...[
            IconButton(
              onPressed: onBackPressed,
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF1565C0),
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
