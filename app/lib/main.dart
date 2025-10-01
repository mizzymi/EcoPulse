import 'package:ecopulse/features/home/widgets/add_house_cta.dart';
import 'package:ecopulse/features/settings/language_picker.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:ecopulse/ui/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/home/widgets/household_carousel.dart';
import 'providers/app_locale_provider.dart';
import 'api/dio.dart';
import 'features/Licence.dart';
import 'features/auth/auth_screen.dart';
import 'features/households/household_detail_screen.dart';
import 'features/households/join_household_screen.dart';
import 'features/households/create_household_screen.dart';
import 'ws/ws_client.dart';
import 'providers/auth_token_provider.dart';
import 'features/households/providers/household_summaries_provider.dart';
import 'package:ecopulse/ui/widgets/glass_card.dart';

void _openAddHouseholdSheet(BuildContext ctx, WidgetRef ref) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: false,
    backgroundColor: Theme.of(ctx).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      final s = S.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(.12),
                  child:
                      const Icon(Icons.add_home_outlined, color: Colors.green),
                ),
                title: Text(s.createAccount),
                onTap: () async {
                  Navigator.pop(ctx);
                  final created = await Navigator.push<Map<String, dynamic>?>(
                    ctx,
                    MaterialPageRoute(
                        builder: (_) => const CreateHouseholdScreen()),
                  );
                  if (created == null) return;

                  // 🔄 fuerza recarga del carrusel
                  ref.invalidate(householdPreviewsProvider);

                  final messenger = ScaffoldMessenger.of(ctx);
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text(s.createdAccount(
                            created['name']?.toString() ?? ''))),
                  );

                  final id = created['id']?.toString();
                  final name = created['name']?.toString();
                  if (id != null) {
                    // Abre detalle
                    // ignore: use_build_context_synchronously
                    await Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => HouseholdDetailScreen(
                            householdId: id, householdName: name),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(.12),
                  child: const Icon(Icons.meeting_room_outlined,
                      color: Colors.blue),
                ),
                title: Text(s.joinAccountByCode),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    ctx,
                    MaterialPageRoute(
                        builder: (_) => const JoinHouseholdScreen()),
                  );
                  // 🔄 fuerza recarga del carrusel
                  ref.invalidate(householdPreviewsProvider);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await registerEulaLicense();

  final container = ProviderContainer();
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('appLocaleCode');
  if (code != null && code != 'system') {
    container.read(appLocaleProvider.notifier).state = Locale(code);
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: const EcoPulseApp(),
  ));
}

Future<void> _bootstrapToken(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('authToken');
  if (saved != null && ref.read(authTokenProvider) == null) {
    ref.read(authTokenProvider.notifier).state = saved;
  }
}

class EcoPulseApp extends ConsumerStatefulWidget {
  const EcoPulseApp({super.key});
  @override
  ConsumerState<EcoPulseApp> createState() => _EcoPulseAppState();
}

class _EcoPulseAppState extends ConsumerState<EcoPulseApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapToken(ref);
      listenJoinEvents(ref, (msg) {
        _messenger.currentState?.showSnackBar(SnackBar(content: Text(msg)));
        // 🔄 recarga el carrusel también al recibir join desde WS
        ref.invalidate(householdPreviewsProvider);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dioProvider);
    final token = ref.watch(authTokenProvider);
    final appLocale = ref.watch(appLocaleProvider);
    return MaterialApp(
      locale: appLocale,
      onGenerateTitle: (ctx) => S.of(ctx).appTitle,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      title: 'EcoPulse',
      scaffoldMessengerKey: _messenger,
      theme: AppTheme.light,
      home: token == null
          ? const AuthScreen()
          : Builder(
              builder: (innerContext) => Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight + 16),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        radius: 16,
                        child: Row(
                          children: [
                            // Icono SVG
                            SvgPicture.asset(
                              'lib/assets/app_icon.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                Theme.of(innerContext).colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Título
                            Expanded(
                              child: Text(
                                S.of(innerContext).appTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(innerContext)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),

                            // Selector de idioma
                            IconButton(
                              tooltip: 'Cambiar idioma',
                              icon: const Icon(Icons.language),
                              onPressed: () =>
                                  showLanguagePicker(innerContext, ref),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        AddHouseCta(
                          onTap: () =>
                              _openAddHouseholdSheet(innerContext, ref),
                        ),
                        const SizedBox(height: 16),
                        const HouseholdCarousel(),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () async {
                            ref.read(authTokenProvider.notifier).state = null;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('authToken');
                          },
                          icon: const Icon(Icons.logout),
                          label: Text(S.of(innerContext).logout),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
