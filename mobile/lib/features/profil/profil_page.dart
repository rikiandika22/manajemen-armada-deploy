import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/features/profil/widgets/profile_guest_view.dart';
import 'package:mobile/features/profil/widgets/profile_user_view.dart';

class ProfilPage extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;

  const ProfilPage({super.key, this.refreshNotifier});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  @override
  void initState() {
    super.initState();
    widget.refreshNotifier?.addListener(_onRefreshNotified);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefreshNotified);
    super.dispose();
  }

  void _onRefreshNotified() {
    if (widget.refreshNotifier?.value == 3) {
      // Re-fetch user data
      AuthState.instance.checkAuthStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AuthState.instance,
          builder: (context, _) {
            if (AuthState.instance.isLoggedIn) {
              return const ProfileUserView();
            } else {
              return const ProfileGuestView();
            }
          },
        ),
      ),
    );
  }
}
