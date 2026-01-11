import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/api_client.dart';
import '../services/data_service.dart';

class AppDrawer extends StatefulWidget {
  final String? currentRoute;
  final String? userName;
  final String? userEmail;
  final String? userAvatar;

  const AppDrawer({
    super.key,
    this.currentRoute,
    this.userName,
    this.userEmail,
    this.userAvatar,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernUserHeader(context),
          _buildLanguageToggle(context),
          Expanded(child: _buildModernNavigationItems(context)),
        ],
      ),
    );
  }

  Widget _buildModernUserHeader(BuildContext context) {
    print('🔍 DEBUG: AppDrawer - userName: ${widget.userName}, userEmail: ${widget.userEmail}, userAvatar: ${widget.userAvatar}');
    // Resolve avatar to network URL only
    String? resolvedNetworkUrl;
    final raw = widget.userAvatar?.trim();
    if (raw != null && raw.isNotEmpty) {
      try {
        if (raw.startsWith('http://') || raw.startsWith('https://')) {
          resolvedNetworkUrl = raw;
        } else if (raw.startsWith('/')) {
          // Relative path from API - prepend /public/ for profile images
          final base = ApiClient.baseUrl;
          final path = raw.startsWith('/public/') ? raw : '/public' + raw;
          final joined = base + path; // base already trimmed of trailing slash
          resolvedNetworkUrl = joined;
        } else {
          // Unknown format; attempt network by prefixing base URL with /public/
          final base = ApiClient.baseUrl;
          final path = raw.startsWith('/') ? '/public' + raw : '/public/' + raw;
          final joined = base + path;
          resolvedNetworkUrl = joined;
        }
        print('🔍 DEBUG: Resolved avatar - networkUrl=$resolvedNetworkUrl');
      } catch (e) {
        print('🔴 DEBUG: Failed to resolve avatar "$raw": $e');
      }
    }
    
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/illustrations/drawer_header_image.jpg'),
          fit: BoxFit.cover ,
        ),
      ),
      child: Container(
       
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: FutureBuilder<String?>(
                      future: DataService.getAuthToken(),
                      builder: (context, snapshot) {
                        if (resolvedNetworkUrl != null) {
                          final token = snapshot.data;
                          final headers = token != null && token.isNotEmpty
                              ? {
                                  'Authorization': 'Bearer ' + token,
                                  'Accept': 'image/*,application/octet-stream'
                                }
                              : null;
                          return Image.network(
                            resolvedNetworkUrl,
                            fit: BoxFit.cover,
                            headers: headers,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                print('🔍 DEBUG: Profile image loaded successfully: $resolvedNetworkUrl');
                                return child;
                              }
                              print('🔍 DEBUG: Loading profile image: $resolvedNetworkUrl');
                              return const Center(child: CircularProgressIndicator(color: Colors.white));
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('🔍 DEBUG: Error loading profile image: $error');
                              return _buildDefaultAvatar(context);
                            },
                          );
                        }
                        return _buildDefaultAvatar(context);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName ?? 'Quick Clinic',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.userEmail ?? 'user@example.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildLanguageToggle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.language,
            color: Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Language',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          _buildLanguageSwitch(),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitch() {
    final currentLanguage = LocalizationService.currentLanguage;
    final isEnglish = currentLanguage == 'en';
    
    return GestureDetector(
      onTap: () {
        final newLanguage = isEnglish ? 'sw' : 'en';
        LocalizationService.setLanguage(newLanguage);
        setState(() {}); // Refresh the UI
      },
      child: Container(
        width: 100,
        height: 30,
        decoration: BoxDecoration(
          color: isEnglish ? Colors.blue : Colors.orange,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: isEnglish ? 2 : 50,
              top: 2,
              child: Container(
                width: 46,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 7,
              child: Text(
                'EN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isEnglish ? Colors.blue : Colors.grey,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 7,
              child: Text(
                'SW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: !isEnglish ? Colors.orange : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNavigationItems(BuildContext context) {
    final navigationItems = [
      // {'title': 'Settings', 'icon': Icons.settings, 'route': '/settings'},
      {'title': 'Profile', 'icon': Icons.person, 'route': '/profile'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: navigationItems.length,
      itemBuilder: (context, index) {
        final item = navigationItems[index];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.pop(context);
                if (widget.currentRoute != item['route']) {
                  Navigator.pushNamed(context, item['route'] as String);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 24,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    if (item['badge'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item['badge'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? iconColor;
  final Color? textColor;

  const DrawerItem({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.isSelected = false,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        border: isSelected ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? (isSelected ? Colors.white : Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: textColor ?? (isSelected ? Theme.of(context).primaryColor : Colors.grey[800]),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}