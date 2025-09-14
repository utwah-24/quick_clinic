import 'package:flutter/material.dart';

class DynamicAppBar extends StatelessWidget {
  final Widget? leading;
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const DynamicAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed, this.leading,
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
              style: const TextStyle(
                // fontFamily: 'sans',
                fontSize: 35,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(250, 19, 25, 90),
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
