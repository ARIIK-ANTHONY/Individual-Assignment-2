import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/listing_model.dart';
import '../models/review_model.dart';
import '../services/listing_service.dart';

enum ListingsStatus { initial, loading, loaded, error }

class ListingsProvider extends ChangeNotifier {
  final ListingService _service;

  ListingsStatus _status = ListingsStatus.initial;
  List<ListingModel> _allListings = [];
  List<ListingModel> _userListings = [];
  List<ReviewModel> _currentReviews = [];
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  StreamSubscription<List<ListingModel>>? _allSub;
  StreamSubscription<List<ListingModel>>? _userSub;
  StreamSubscription<List<ReviewModel>>? _reviewsSub;
  Timer? _searchDebounce;
  DateTime? _lastTransientErrorAt;

  bool _canEmitTransientError() {
    final now = DateTime.now();
    if (_lastTransientErrorAt == null ||
        now.difference(_lastTransientErrorAt!) > const Duration(seconds: 10)) {
      _lastTransientErrorAt = now;
      return true;
    }
    return false;
  }

  ListingsProvider(this._service);

  ListingsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<ReviewModel> get currentReviews => _currentReviews;
  List<ListingModel> get allListings => _allListings;
  List<ListingModel> get userListings => _userListings;

  List<ListingModel> get filteredListings {
    var results = List<ListingModel>.from(_allListings);
    if (_selectedCategory != 'All') {
      results = results
          .where((l) =>
              _normalizeCategory(l.category) ==
              _normalizeCategory(_selectedCategory))
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      results = results
          .where((l) =>
              l.name.toLowerCase().contains(q) ||
              l.address.toLowerCase().contains(q) ||
              l.description.toLowerCase().contains(q))
          .toList();
    }
    return results;
  }

  String _normalizeCategory(String value) {
    final c = value.trim().toLowerCase();
    if (c == 'cafe' || c == 'café') return 'cafe';
    return c;
  }

  void subscribeToAllListings() {
    _status = ListingsStatus.loading;
    notifyListeners();
    _allSub?.cancel();
    _allSub = _service.getListingsStream().listen(
      (list) {
        _allListings = list;
        _errorMessage = null;
        _status = ListingsStatus.loaded;
        notifyListeners();
      },
      onError: (e) {
        final msg = e.toString().toLowerCase();
        final isTransient = msg.contains('unavailable') ||
            msg.contains('unable to resolve host');

        if (isTransient && !_canEmitTransientError()) {
          return;
        }

        if (msg.contains('unavailable') ||
            msg.contains('unable to resolve host')) {
          _errorMessage =
              'Network unavailable. Check emulator internet and try again.';
        } else {
          _errorMessage = 'Failed to load listings: $e';
        }
        _status = _allListings.isNotEmpty
            ? ListingsStatus.loaded
            : ListingsStatus.error;
        notifyListeners();
      },
    );
  }

  void subscribeToUserListings(String uid) {
    _userSub?.cancel();
    _userSub = _service.getUserListingsStream(uid).listen(
      (list) {
        _userListings = list;
        notifyListeners();
      },
      onError: (e) {
        final msg = e.toString().toLowerCase();
        if ((msg.contains('unavailable') ||
                msg.contains('unable to resolve host')) &&
            !_canEmitTransientError()) {
          return;
        }
        _errorMessage = 'Failed to load your listings: $e';
        notifyListeners();
      },
    );
  }

  void updateSearch(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (_searchQuery == q) return;
      _searchQuery = q;
      notifyListeners();
    });
  }

  void updateCategory(String c) {
    _selectedCategory = c;
    _searchQuery = ''; // clear search so category results are never stale
    notifyListeners();
  }

  void clearFilters() {
    _searchDebounce?.cancel();
    _selectedCategory = 'All';
    _searchQuery = '';
    notifyListeners();
  }

  void _upsertLocalListing(ListingModel listing) {
    final allIdx = _allListings.indexWhere((x) => x.id == listing.id);
    if (allIdx == -1) {
      _allListings.insert(0, listing);
    } else {
      _allListings[allIdx] = listing;
    }

    final userIdx = _userListings.indexWhere((x) => x.id == listing.id);
    if (userIdx == -1) {
      _userListings.insert(0, listing);
    } else {
      _userListings[userIdx] = listing;
    }
  }

  Future<bool> createListing(ListingModel l) async {
    try {
      final id = await _service.createListing(l);
      _upsertLocalListing(l.copyWith(id: id));
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> ensureStarterListings({
    required String createdByUid,
    required String createdByName,
  }) async {
    try {
      await _service.ensureStarterListings(
        createdByUid: createdByUid,
        createdByName: createdByName,
      );
    } catch (e) {
      _errorMessage = 'Failed to initialize starter places: $e';
      notifyListeners();
    }
  }

  Future<bool> updateListing(ListingModel l) async {
    try {
      await _service.updateListing(l);
      _upsertLocalListing(l);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteListing(String id) async {
    try {
      await _service.deleteListing(id);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete: $e';
      notifyListeners();
      return false;
    }
  }

  void loadReviews(String listingId) {
    _reviewsSub?.cancel();
    _reviewsSub = _service.getReviewsStream(listingId).listen(
      (r) {
        _currentReviews = r;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        final msg = e.toString().toLowerCase();
        final isTransient = msg.contains('unavailable') ||
            msg.contains('unable to resolve host');

        if (isTransient && !_canEmitTransientError()) {
          return;
        }

        if (msg.contains('unavailable') ||
            msg.contains('unable to resolve host')) {
          _errorMessage =
              'Reviews are unavailable while offline. Reconnect and retry.';
        } else {
          _errorMessage = 'Failed to load reviews: $e';
        }
        notifyListeners();
      },
    );
  }

  Future<bool> addReview(ReviewModel r) async {
    try {
      await _service.addReview(r);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit review: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _allSub?.cancel();
    _userSub?.cancel();
    _reviewsSub?.cancel();
    super.dispose();
  }
}
