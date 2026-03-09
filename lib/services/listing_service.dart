import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../models/review_model.dart';

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _listings => _db.collection('listings');
  CollectionReference get _reviews => _db.collection('reviews');

  Stream<List<ListingModel>> getListingsStream() => _listings
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ListingModel.fromFirestore).toList());

  Stream<List<ListingModel>> getUserListingsStream(String uid) => _listings
      .where('createdBy', isEqualTo: uid)
      .snapshots()
      .map((s) {
        final items = s.docs.map(ListingModel.fromFirestore).toList();
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      });

  Future<String> createListing(ListingModel l) async {
    final ref = await _listings.add(l.toFirestore());
    return ref.id;
  }

  Future<void> updateListing(ListingModel l) =>
      _listings.doc(l.id).update(l.toFirestore());

  Future<void> deleteListing(String id) async {
    await _listings.doc(id).delete();
    final reviews = await _reviews.where('listingId', isEqualTo: id).get();
    for (final d in reviews.docs) await d.reference.delete();
  }

  Stream<List<ReviewModel>> getReviewsStream(String listingId) => _reviews
      .where('listingId', isEqualTo: listingId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ReviewModel.fromFirestore).toList());

  Future<void> addReview(ReviewModel review) async {
    await _reviews.add(review.toFirestore());
    await _db.runTransaction((tx) async {
      final ref = _listings.doc(review.listingId);
      final doc = await tx.get(ref);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final count = (data['reviewCount'] ?? 0).toInt();
        final rating = (data['rating'] ?? 0.0).toDouble();
        final newCount = count + 1;
        final newRating = ((rating * count) + review.rating) / newCount;
        tx.update(ref, {'rating': newRating, 'reviewCount': newCount});
      }
    });
  }

  Future<void> ensureStarterListings({
    required String createdByUid,
    required String createdByName,
  }) async {
    final existing = await _listings.get();
    final existingKeys = <String>{};
    for (final doc in existing.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().trim().toLowerCase();
      final category = (data['category'] ?? '').toString().trim().toLowerCase();
      existingKeys.add('$category|$name');
    }

    final now = DateTime.now();
    final starterListings = <Map<String, dynamic>>[
      ListingModel(
        id: '',
        name: 'King Faisal Hospital',
        category: 'Hospital',
        address: 'KG 544 St, Kigali',
        contactNumber: '+250 788 123 456',
        description: 'Major referral hospital with emergency care services.',
        latitude: -1.9441,
        longitude: 30.0920,
        createdBy: createdByUid,
        createdByName: createdByName,
        createdAt: now,
      ).toFirestore(),
      ListingModel(
        id: '',
        name: 'Remera Police Station',
        category: 'Police Station',
        address: 'KG 11 Ave, Remera, Kigali',
        contactNumber: '+250 788 111 112',
        description: 'Community policing and rapid response point.',
        latitude: -1.9496,
        longitude: 30.1053,
        createdBy: createdByUid,
        createdByName: createdByName,
        createdAt: now,
      ).toFirestore(),
      ListingModel(
        id: '',
        name: 'Kigali Public Library',
        category: 'Library',
        address: 'KN 5 Rd, Nyarugenge, Kigali',
        contactNumber: '+250 788 222 333',
        description: 'Public reading and study space with internet access.',
        latitude: -1.9515,
        longitude: 30.0619,
        createdBy: createdByUid,
        createdByName: createdByName,
        createdAt: now,
      ).toFirestore(),
      ListingModel(
        id: '',
        name: 'Question Coffee Cafe',
        category: 'Café',
        address: 'KG 674 St, Gishushu, Kigali',
        contactNumber: '+250 788 333 444',
        description: 'Popular cafe with local coffee and light meals.',
        latitude: -1.9499,
        longitude: 30.1058,
        createdBy: createdByUid,
        createdByName: createdByName,
        createdAt: now,
      ).toFirestore(),
      ListingModel(
        id: '',
        name: 'Heaven Restaurant Kigali',
        category: 'Restaurant',
        address: 'KN 29 St, Kiyovu, Kigali',
        contactNumber: '+250 788 555 666',
        description: 'Well-known restaurant serving local and international cuisine.',
        latitude: -1.9490,
        longitude: 30.0588,
        createdBy: createdByUid,
        createdByName: createdByName,
        createdAt: now,
      ).toFirestore(),
      ListingModel(
        id: '',
        name: 'Kigali Convention Centre Park',
        category: 'Park',
        address: 'KG 2 Roundabout, Kigali',
        contactNumber: '+250 788 444 555',
        description: 'Open green space near KCC suitable for walks.',
        latitude: -1.9556,
        longitude: 30.0931,
        createdBy: createdByUid,
        createdByName: createdByName,
        createdAt: now,
      ).toFirestore(),
    ];

    final batch = _db.batch();
    var addedCount = 0;
    for (final data in starterListings) {
      final name = (data['name'] ?? '').toString().trim().toLowerCase();
      final category = (data['category'] ?? '').toString().trim().toLowerCase();
      final key = '$category|$name';
      if (existingKeys.contains(key)) continue;
      final ref = _listings.doc();
      batch.set(ref, data);
      addedCount++;
    }
    if (addedCount > 0) {
      await batch.commit();
    }
  }
}
