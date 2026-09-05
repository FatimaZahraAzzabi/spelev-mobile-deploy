import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class ProfileAvatar extends StatefulWidget {
  final String initiale;
  final bool hasPhoto;
  final int refreshKey;

  const ProfileAvatar({super.key, required this.initiale, required this.hasPhoto, required this.refreshKey});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _error = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) setState(() => _error = false);
  }

  Future<void> _loadToken() async {
    const storage = FlutterSecureStorage();
    _token = await storage.read(key: 'jwt_token');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasPhoto || _token == null || _error) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: AppColors.navy,
        child: Text(widget.initiale, style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }

    final photoProxyUrl = '${ApiConfig.baseUrl}/api/utilisateurs/photo?t=${widget.refreshKey}';
    return CircleAvatar(
      radius: 60,
      key: ValueKey('avatar_${widget.refreshKey}'),
      backgroundImage: NetworkImage(photoProxyUrl, headers: {'Authorization': 'Bearer $_token'}),
      onBackgroundImageError: (_, __) { if (mounted) setState(() => _error = true); },
    );
  }
}