import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/listings_provider.dart';
import '../../theme/app_theme.dart';
import '../listings/listing_detail_screen.dart';
import '../listings/add_edit_listing_screen.dart';

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  void _openAddListing(BuildContext context) {
    final auth = context.read<ap.AuthProvider>();
    final listings = context.read<ListingsProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<ap.AuthProvider>.value(value: auth),
            ChangeNotifierProvider<ListingsProvider>.value(value: listings),
          ],
          child: const AddEditListingScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kigali City'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openAddListing(context),
          ),
        ],
      ),
      body: const Column(children: [
        _CategoryChips(),
        _SearchBar(),
        Expanded(child: _ListingsView()),
      ]),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListingsProvider>();
    const categories = AppConstants.categories;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = provider.selectedCategory == cat;
          return FilterChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => provider.updateCategory(cat),
            backgroundColor: AppTheme.chipBackground,
            selectedColor: AppTheme.accentGold,
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              fontSize: 13,
            ),
            side: BorderSide(
                color: isSelected ? AppTheme.accentGold : AppTheme.divider),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar();
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the text field in sync when category switch clears the query.
    final query = context.watch<ListingsProvider>().searchQuery;
    if (_ctrl.text != query) {
      _ctrl.value = _ctrl.value.copyWith(text: query);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _ctrl,
        style: const TextStyle(color: AppTheme.textPrimary),
        onChanged: context.read<ListingsProvider>().updateSearch,
        decoration: const InputDecoration(
          hintText: 'Search for a service...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.tune_outlined),
        ),
      ),
    );
  }
}

class _ListingsView extends StatelessWidget {
  const _ListingsView();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListingsProvider>();

    if (provider.status == ListingsStatus.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold));
    }
    if (provider.status == ListingsStatus.error) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
        const SizedBox(height: 12),
        Text(provider.errorMessage ?? 'Failed to load listings',
            style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        TextButton(
            onPressed: provider.subscribeToAllListings,
            child: const Text('Retry')),
      ]));
    }

    final listings = provider.filteredListings;
    if (listings.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off,
            color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 64),
        const SizedBox(height: 16),
        const Text('No listings found',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Try a different search or category',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          provider.selectedCategory == 'All'
              ? 'Near You  (${listings.length})'
              : '${provider.selectedCategory}  (${listings.length})',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: listings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ListingCard(listing: listings[i]),
        ),
      ),
    ]);
  }
}

class _ListingCard extends StatelessWidget {
  final ListingModel listing;
  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.categoryIcons[listing.category] ?? '📍';
    return InkWell(
      onTap: () {
        final auth = context.read<ap.AuthProvider>();
        final listings = context.read<ListingsProvider>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider<ap.AuthProvider>.value(value: auth),
                ChangeNotifierProvider<ListingsProvider>.value(
                    value: listings),
              ],
              child: ListingDetailScreen(listing: listing),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: AppTheme.chipBackground,
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(listing.name,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                if (listing.rating > 0) ...[
                  const SizedBox(width: 8),
                  Text(listing.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 3),
                  const Icon(Icons.star, color: AppTheme.accentGold, size: 14),
                ],
              ]),
              const SizedBox(height: 4),
              RatingBarIndicator(
                rating: listing.rating,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: AppTheme.accentGold),
                itemCount: 5,
                itemSize: 14,
                unratedColor: AppTheme.divider,
              ),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(listing.category,
                      style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined,
                    color: AppTheme.textSecondary, size: 12),
                const SizedBox(width: 2),
                Text(
                  listing.address.length > 20
                      ? '${listing.address.substring(0, 20)}...'
                      : listing.address,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ]),
            ],
          )),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              color: AppTheme.textSecondary, size: 20),
        ]),
      ),
    );
  }
}
