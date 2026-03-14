import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/listing_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/listings_provider.dart';
import '../../theme/app_theme.dart';
import 'add_edit_listing_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;
  const ListingDetailScreen({super.key, required this.listing});
  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  double _userRating = 0;
  final _reviewCtrl = TextEditingController();

  bool _hasDefaultKigaliCoordinates(ListingModel l) {
    const epsilon = 0.0002;
    return (l.latitude - AppConstants.kigaliLat).abs() < epsilon &&
        (l.longitude - AppConstants.kigaliLng).abs() < epsilon;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ListingsProvider>().loadReviews(widget.listing.id));
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<bool> _tryLaunchExternal(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException catch (e) {
      debugPrint('Launch failed for $uri: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Launch failed for $uri: $e');
      return false;
    }
  }

  Future<void> _launchNavigation() async {
    final l = widget.listing;
    final useAddressQuery = _hasDefaultKigaliCoordinates(l);
    final addressQuery = '${l.name}, ${l.address}, Rwanda';
    final destination =
        useAddressQuery ? addressQuery : '${l.latitude},${l.longitude}';

    // Prefer native map intents on Android to avoid webview interception.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final navUri = Uri.parse(
          'google.navigation:q=${Uri.encodeComponent(destination)}&mode=d');
      if (await _tryLaunchExternal(navUri)) {
        return;
      }

      final geoUri = useAddressQuery
          ? Uri.parse('geo:0,0?q=${Uri.encodeComponent(addressQuery)}')
          : Uri.parse('geo:${l.latitude},${l.longitude}?q=$destination');
      if (await _tryLaunchExternal(geoUri)) {
        return;
      }
    }

    final webUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    });
    if (await _tryLaunchExternal(webUri)) {
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open maps navigation on this device.')));
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: widget.listing.contactNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _submitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a rating')));
      return;
    }
    final auth = context.read<ap.AuthProvider>();
    final review = ReviewModel(
      id: '',
      listingId: widget.listing.id,
      userId: auth.user!.uid,
      userName: auth.userProfile?.displayName ?? 'Anonymous',
      rating: _userRating,
      comment: _reviewCtrl.text.trim(),
      createdAt: DateTime.now(),
    );
    final listings = context.read<ListingsProvider>();
    final success = await listings.addReview(review);
    if (!mounted) return;
    if (!success) {
      final message = listings.errorMessage ?? 'Failed to submit review.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (mounted) {
      setState(() => _userRating = 0);
      _reviewCtrl.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Review submitted!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final auth = context.watch<ap.AuthProvider>();
    final isOwner = auth.user?.uid == l.createdBy;
    final emoji = AppConstants.categoryIcons[l.category] ?? '📍';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A2D3D), Color(0xFF0E1822)],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place,
                            color: AppTheme.accentGold, size: 52),
                        const SizedBox(height: 10),
                        Text(
                          l.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.address,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    final auth = context.read<ap.AuthProvider>();
                    final listings = context.read<ListingsProvider>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider<ap.AuthProvider>.value(
                                value: auth),
                            ChangeNotifierProvider<ListingsProvider>.value(
                                value: listings),
                          ],
                          child: AddEditListingScreen(listing: l),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.errorRed),
                  onPressed: _confirmDelete,
                ),
              ],
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(l.name,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(l.category,
                          style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (l.rating > 0) ...[
                      const SizedBox(width: 10),
                      RatingBarIndicator(
                          rating: l.rating,
                          itemSize: 16,
                          itemBuilder: (_, __) => const Icon(Icons.star,
                              color: AppTheme.accentGold),
                          unratedColor: AppTheme.divider),
                      const SizedBox(width: 6),
                      Text('${l.rating.toStringAsFixed(1)} (${l.reviewCount})',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ]),
                  const SizedBox(height: 16),
                  Text(l.description,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, height: 1.6)),
                  const SizedBox(height: 12),
                  if (l.createdByName.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.person_outline,
                          color: AppTheme.textSecondary, size: 14),
                      const SizedBox(width: 6),
                      Text('Added by ${l.createdByName}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ]),
                  const SizedBox(height: 20),

                  _InfoRow(icon: Icons.location_on_outlined, text: l.address),
                  if (l.contactNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        text: l.contactNumber,
                        onTap: _launchPhone),
                  ],
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.my_location_outlined,
                      text: '${l.latitude.toStringAsFixed(4)}, '
                          '${l.longitude.toStringAsFixed(4)}'),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _launchNavigation,
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Get Directions'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _launchPhone,
                    icon: const Icon(Icons.call_outlined,
                        color: AppTheme.accentGold),
                    label: const Text('Call',
                        style: TextStyle(color: AppTheme.accentGold)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppTheme.accentGold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 16),

                  // Reviews
                  const _ReviewsSection(),
                  const SizedBox(height: 24),
                  _AddReviewSection(
                    userRating: _userRating,
                    onRatingChanged: (r) => setState(() => _userRating = r),
                    controller: _reviewCtrl,
                    onSubmit: _submitReview,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.cardDark,
              title: const Text('Delete Listing'),
              content:
                  Text('Delete "${widget.listing.name}"? Cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await context
                        .read<ListingsProvider>()
                        .deleteListing(widget.listing.id);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      minimumSize: const Size(80, 40)),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _InfoRow({required this.icon, required this.text, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(icon, color: AppTheme.accentGold, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                      color: onTap != null
                          ? AppTheme.accentGold
                          : AppTheme.textSecondary,
                      fontSize: 14,
                      decoration:
                          onTap != null ? TextDecoration.underline : null,
                    ))),
          ]),
        ),
      );
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection();
  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ListingsProvider>().currentReviews;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Reviews',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(width: 8),
        Text('(${reviews.length})',
            style: const TextStyle(color: AppTheme.textSecondary)),
      ]),
      const SizedBox(height: 12),
      if (reviews.isEmpty)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No reviews yet. Be the first to review!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)))
      else
        ...reviews.map((r) => _ReviewCard(review: r)),
    ]);
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.chipBackground,
            borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentGold.withValues(alpha: 0.2),
              child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                      color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text(review.userName,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            const Spacer(),
            RatingBarIndicator(
                rating: review.rating,
                itemSize: 13,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: AppTheme.accentGold),
                unratedColor: AppTheme.divider),
          ]),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${review.comment}"',
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ],
        ]),
      );
}

class _AddReviewSection extends StatelessWidget {
  final double userRating;
  final ValueChanged<double> onRatingChanged;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _AddReviewSection({
    required this.userRating,
    required this.onRatingChanged,
    required this.controller,
    required this.onSubmit,
  });
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rate this service',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Center(
              child: RatingBar.builder(
            initialRating: userRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 36,
            itemBuilder: (_, __) =>
                const Icon(Icons.star, color: AppTheme.accentGold),
            unratedColor: AppTheme.divider,
            onRatingUpdate: onRatingChanged,
          )),
          const SizedBox(height: 12),
          TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                  hintText: 'Write a review (optional)...')),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: onSubmit, child: const Text('Submit Review')),
        ],
      );
}
