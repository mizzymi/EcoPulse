import 'package:ecopulse/features/households/household_detail_screen.dart';
import 'package:ecopulse/features/households/providers/household_summaries_provider.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopulse/ui/widgets/household_card.dart';
import 'package:intl/intl.dart';

class HouseholdCarousel extends ConsumerStatefulWidget {
  const HouseholdCarousel({super.key});
  @override
  ConsumerState<HouseholdCarousel> createState() => _HouseholdCarouselState();
}

class _HouseholdCarouselState extends ConsumerState<HouseholdCarousel> {
  final _controller = PageController(viewportFraction: .86);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(householdPreviewsProvider);

    return data.when(
        loading: () => SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _controller,
                itemBuilder: (_, __) => _skeletonCard(context),
                itemCount: 3,
              ),
            ),
        error: (e, st) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${S.of(context).householdCarouselError}: $e'),
            ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(S.of(context).householdCarouselEmpty),
            );
          }

          String membersLabel(BuildContext ctx, int n) {
            return S.of(ctx).householdMembersCount(n);
          }

          String fmt(BuildContext ctx, double v, String currency) {
            final locale = Localizations.localeOf(ctx).toLanguageTag();
            final f =
                NumberFormat.simpleCurrency(locale: locale, name: currency);
            return f.format(v);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final h = list[i];
                    final members = membersLabel(context, h.memberCount);
                    final amount = fmt(context, h.closingBalance, h.currency);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: HouseholdCard(
                        title: h.name,
                        subtitle: members,
                        amount: amount,
                        onOpen: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => HouseholdDetailScreen(
                              householdId: h.id,
                              householdName: h.name,
                            ),
                          ));
                          if (!mounted) return;
                          ref.invalidate(householdPreviewsProvider);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _Dots(count: list.length, index: _index),
            ],
          );
        });
  }

  Widget _skeletonCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 22 : 8,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.primary.withOpacity(.25),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
