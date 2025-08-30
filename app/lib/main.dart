import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/dio.dart';
import 'features/auth/auth_screen.dart';
import 'features/households/household_detail_screen.dart';
import 'features/households/join_household_screen.dart';
import 'features/households/create_household_screen.dart';
import 'features/households/my_households_screen.dart';
import 'ws/ws_client.dart';
import 'providers/auth_token_provider.dart';

void main() {
  runApp(const ProviderScope(child: EcoPulseApp()));
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
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dioProvider);
    final token = ref.watch(authTokenProvider);

    return MaterialApp(
      title: 'EcoPulse (Windows)',
      scaffoldMessengerKey: _messenger,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 113, 67, 139),
        ),
      ),
      home: token == null
          ? const AuthScreen()
          : Builder(
              builder: (innerContext) => Scaffold(
                appBar: AppBar(
                  title: const Text('EcoPulse - Households'),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SvgPicture.asset(
                        'lib/assets/app_icon.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Mis casas'),
                          onPressed: () {
                            Navigator.push(
                              innerContext,
                              MaterialPageRoute(
                                builder: (_) => const MyHouseholdsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Crear una casa'),
                          onPressed: () async {
                            final created =
                                await Navigator.push<Map<String, dynamic>?>(
                              innerContext,
                              MaterialPageRoute(
                                builder: (_) => const CreateHouseholdScreen(),
                              ),
                            );

                            if (!mounted || created == null) return;

                            _messenger.currentState?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Casa creada: ${created['name'] ?? ''}',
                                ),
                              ),
                            );

                            final id = created['id']?.toString();
                            final name = created['name']?.toString();
                            if (id != null) {
                              await Navigator.push(
                                innerContext,
                                MaterialPageRoute(
                                  builder: (_) => HouseholdDetailScreen(
                                    householdId: id,
                                    householdName: name,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.meeting_room_outlined),
                          label: const Text('Unirse a una casa por código'),
                          onPressed: () {
                            Navigator.push(
                              innerContext,
                              MaterialPageRoute(
                                builder: (_) => const JoinHouseholdScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () async {
                            ref.read(authTokenProvider.notifier).state = null;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('authToken');
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
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
