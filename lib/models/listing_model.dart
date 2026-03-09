import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String name;
  final String category;
  final String address;
  final String contactNumber;
  final String description;
  final double latitude;
  final double longitude;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final double rating;
  final int reviewCount;
  final double distanceKm;

  ListingModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.contactNumber,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    this.createdByName = '',
    required this.createdAt,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.distanceKm = 0.0,
  });

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      address: data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? -1.9440727).toDouble(),
      longitude: (data['longitude'] ?? 30.0618851).toDouble(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'address': address,
        'contactNumber': contactNumber,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
        'rating': rating,
        'reviewCount': reviewCount,
      };

  ListingModel copyWith({
    String? id,
    String? name,
    String? category,
    String? address,
    String? contactNumber,
    String? description,
    double? latitude,
    double? longitude,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    double? rating,
    int? reviewCount,
    double? distanceKm,
  }) =>
      ListingModel(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        address: address ?? this.address,
        contactNumber: contactNumber ?? this.contactNumber,
        description: description ?? this.description,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        createdBy: createdBy ?? this.createdBy,
        createdByName: createdByName ?? this.createdByName,
        createdAt: createdAt ?? this.createdAt,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        distanceKm: distanceKm ?? this.distanceKm,
      );
}
