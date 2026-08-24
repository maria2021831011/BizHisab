import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/locale_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final businessId = auth.user?.businessId;
      if (businessId != null) {
        context.read<BusinessProvider>().loadBusiness(businessId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserCard(l),
            const SizedBox(height: 16),
            _buildBusinessCard(l),
            const SizedBox(height: 16),
            _buildSubscriptionCard(l),
            const SizedBox(height: 16),
            _buildSettingsSection(l),
            const SizedBox(height: 16),
            _buildLogoutButton(l),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AppLocalizations l) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.user?.mobileNumber ?? l.profileUnknownUser,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l.profileBusinessOwner,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessCard(AppLocalizations l) {
    return Consumer<BusinessProvider>(
      builder: (context, biz, _) {
        if (biz.business == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l.profileNoBusiness),
            ),
          );
        }

        final business = biz.business!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.profileBusinessInfo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(),
                _infoRow(l.profileFieldBusinessName, business.name),
                _infoRow(l.profileFieldType, business.businessType),
                _infoRow(l.profileFieldOwner, business.ownerName),
                _infoRow(l.profileFieldPhone, business.phone),
                if (business.address.isNotEmpty)
                  _infoRow(l.profileFieldAddress, business.address),
                _infoRow(l.profileFieldCurrency, business.currency),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(AppLocalizations l) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isActive = auth.user?.isSubscriptionActive ?? false;
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.workspace_premium,
                  color: isActive ? AppColors.success : AppColors.error,
                ),
                title: Text(l.profileSubscriptionTitle),
                subtitle: Text(
                  isActive
                      ? l.profileSubscriptionActive
                      : l.profileSubscriptionInactive,
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  l.profileSubscriptionMonthly,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              if (isActive) ...[
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.cancel_outlined, color: AppColors.error),
                  title: Text(
                    l.profileUnsubscribe,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    l.profileUnsubscribeSubtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => _handleUnsubscribe(auth),
                ),
              ],
              if (!isActive && auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    auth.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleUnsubscribe(AuthProvider auth) async {
    final l = AppLocalizations.of(context);
    auth.clearError();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.profileUnsubscribeTitle),
        content: Text(l.profileUnsubscribeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.profileKeepSubscription),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.profileUnsubscribe),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await auth.unsubscribe();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l.profileUnsubscribeSuccess
              : (auth.errorMessage ?? l.profileUnsubscribeFailed),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );

    if (ok) auth.clearError();
  }

  Widget _buildSettingsSection(AppLocalizations l) {
    return Card(
      child: Column(
        children: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              final code = localeProvider.locale.languageCode;
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(l.language),
                subtitle: Text(
                    code == 'bn' ? l.languageBangla : l.languageEnglish),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(localeProvider),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l.profileEditBusiness),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              // Wait for the edit screen to pop so we can refresh the
              // cached business on return. The edit screen calls
              // BusinessProvider.updateBusinessModel which already
              // updates `_business` in memory, but a re-read is cheap
              // insurance against stale UI.
              await context.push('/app/profile/edit');
              if (!mounted) return;
              final auth = context.read<AuthProvider>();
              final id = auth.user?.businessId;
              if (id != null) {
                await context.read<BusinessProvider>().loadBusiness(id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AppLocalizations l) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppColors.error),
        title: Text(l.profileLogout,
            style: const TextStyle(color: AppColors.error)),
        onTap: () async {
          final auth = context.read<AuthProvider>();
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l.profileLogoutTitle),
              content: Text(l.profileLogoutBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.commonCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.error),
                  child: Text(l.profileLogout),
                ),
              ],
            ),
          );

          if (confirmed == true && mounted) {
            await auth.signOut();
            if (mounted) {
              context.go('/landing');
            }
          }
        },
      ),
    );
  }

  void _showLanguageDialog(LocaleProvider localeProvider) {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.selectLanguage),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: RadioGroup<String>(
            groupValue: localeProvider.locale.languageCode,
            onChanged: (value) {
              if (value == null) return;
              Navigator.pop(dialogContext);
              localeProvider.setLocale(Locale(value));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(l.languageEnglish),
                  value: 'en',
                ),
                RadioListTile<String>(
                  title: Text(l.languageBangla),
                  value: 'bn',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
