import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/listings_provider.dart';
import '../../theme/app_theme.dart';
import 'add_edit_listing_screen.dart';
import 'listing_detail_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditListingScreen())),
          ),
        ],
      ),
      body: Consumer2<ap.AuthProvider, ListingsProvider>(
        builder: (_, auth, listings, __) {
          final items = listings.userListings;
          if (items.isEmpty) {
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_location_alt_outlined,
                  size: 72,
                  color: AppTheme.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text('No listings yet',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Add your first listing to help others',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddEditListingScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Add Listing'),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
              ),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _MyListingCard(
              listing: items[i],
              onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddEditListingScreen(listing: items[i]))),
              onDelete: () => _confirmDelete(context, listings, items[i]),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ListingsProvider provider, ListingModel listing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Listing'),
        content: Text('Delete "${listing.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteListing(listing.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Listing deleted'),
                    backgroundColor: AppTheme.errorRed));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                minimumSize: const Size(80, 40)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onEdit, onDelete;
  const _MyListingCard(
      {required this.listing, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.categoryIcons[listing.category] ?? '📍';
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ListingDetailScreen(listing: listing))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider)),
        child: Row(children: [
          Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: AppTheme.chipBackground,
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(listing.name,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(listing.category,
                      style: const TextStyle(
                          color: AppTheme.accentGold, fontSize: 11)),
                ),
                if (listing.reviewCount > 0) ...[
                  const SizedBox(width: 8),
                  RatingBarIndicator(
                      rating: listing.rating,
                      itemSize: 12,
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star, color: AppTheme.accentGold),
                      unratedColor: AppTheme.divider),
                  const SizedBox(width: 4),
                  Text('(${listing.reviewCount})',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ]),
              const SizedBox(height: 3),
              Text(listing.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          )),
          Column(children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.accentGold, size: 20),
              onPressed: onEdit,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.errorRed, size: 20),
              onPressed: onDelete,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
            ),
          ]),
        ]),
      ),
    );
  }
}
