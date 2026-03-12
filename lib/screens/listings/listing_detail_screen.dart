import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapCtrl;
  double _userRating = 0;
  final _reviewCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ListingsProvider>().loadReviews(widget.listing.id));
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _mapCtrl?.dispose();
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

    // Prefer native map intents on Android to avoid webview interception.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final navUri =
          Uri.parse('google.navigation:q=${l.latitude},${l.longitude}&mode=d');
      if (await _tryLaunchExternal(navUri)) {
        return;
      }

      final label = Uri.encodeComponent(l.name);
      final geoUri = Uri.parse(
          'geo:${l.latitude},${l.longitude}?q=${l.latitude},${l.longitude}($label)');
      if (await _tryLaunchExternal(geoUri)) {
        return;
      }
    }

    final webUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${l.latitude},${l.longitude}',
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
    await context.read<ListingsProvider>().addReview(review);
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
              background: GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: LatLng(l.latitude, l.longitude), zoom: 15),
                markers: {
                  Marker(
                    markerId: MarkerId(l.id),
                    position: LatLng(l.latitude, l.longitude),
                    infoWindow: InfoWindow(title: l.name),
                  )
                },
                onMapCreated: (c) => _mapCtrl = c,
                zoomControlsEnabled: false,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddEditListingScreen(listing: l))),
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
