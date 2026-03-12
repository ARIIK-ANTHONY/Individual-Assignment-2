import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/listings_provider.dart';
import '../../theme/app_theme.dart';

class AddEditListingScreen extends StatefulWidget {
  final ListingModel? listing;
  const AddEditListingScreen({super.key, this.listing});
  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl,
      _addressCtrl,
      _contactCtrl,
      _descCtrl,
      _latCtrl,
      _lngCtrl;
  late String _selectedCategory;
  bool _isSaving = false;
  bool _isLocating = false;

  static const _minRwandaLat = -2.9;
  static const _maxRwandaLat = -1.0;
  static const _minRwandaLng = 28.8;
  static const _maxRwandaLng = 30.95;

  bool get isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _nameCtrl = TextEditingController(text: l?.name ?? '');
    _addressCtrl = TextEditingController(text: l?.address ?? '');
    _contactCtrl = TextEditingController(text: l?.contactNumber ?? '');
    _descCtrl = TextEditingController(text: l?.description ?? '');
    _latCtrl = TextEditingController(
        text: l?.latitude.toString() ?? AppConstants.kigaliLat.toString());
    _lngCtrl = TextEditingController(
        text: l?.longitude.toString() ?? AppConstants.kigaliLng.toString());
    _selectedCategory = l?.category ?? AppConstants.categories[1];

    // New listings default to current device coordinates for map accuracy.
    if (!isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getLocation();
      });
    }
  }

  bool _isInRwanda(double lat, double lng) {
    return lat >= _minRwandaLat &&
        lat <= _maxRwandaLat &&
        lng >= _minRwandaLng &&
        lng <= _maxRwandaLng;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _addressCtrl,
      _contactCtrl,
      _descCtrl,
      _latCtrl,
      _lngCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isLocating = true);
    try {
      bool svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) throw Exception('Location services disabled');
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw Exception('Permission denied');
        }
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedLat = double.tryParse(_latCtrl.text);
    final parsedLng = double.tryParse(_lngCtrl.text);
    if (parsedLat == null || parsedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please provide valid latitude and longitude.')));
      return;
    }
    if (!_isInRwanda(parsedLat, parsedLng)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Coordinates must be in Rwanda. Tap "Use Current" to autofill.')));
      return;
    }

    setState(() => _isSaving = true);
    final auth = context.read<ap.AuthProvider>();
    final provider = context.read<ListingsProvider>();
    final listing = ListingModel(
      id: widget.listing?.id ?? '',
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      address: _addressCtrl.text.trim(),
      contactNumber: _contactCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      latitude: parsedLat,
      longitude: parsedLng,
      createdBy: auth.user!.uid,
      createdByName: auth.userProfile?.displayName ?? '',
      createdAt: widget.listing?.createdAt ?? DateTime.now(),
      rating: widget.listing?.rating ?? 0.0,
      reviewCount: widget.listing?.reviewCount ?? 0,
    );
    final ok = isEditing
        ? await provider.updateListing(listing)
        : await provider.createListing(listing);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEditing ? 'Listing updated!' : 'Listing created!'),
        backgroundColor: AppTheme.successGreen,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.errorMessage ?? 'Save failed'),
        backgroundColor: AppTheme.errorRed,
      ));
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Listing' : 'Add Listing'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.accentGold))
                : const Text('Save',
                    style: TextStyle(color: AppTheme.accentGold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Place / Service Name'),
            TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'e.g. Kimironko Market'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null),
            const SizedBox(height: 20),
            _label('Category'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: AppTheme.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                  isExpanded: true,
                  dropdownColor: AppTheme.cardDark,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: AppConstants.categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(children: [
                            Text(AppConstants.categoryIcons[c] ?? '📍'),
                            const SizedBox(width: 8),
                            Text(c),
                          ])))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _label('Address'),
            TextFormField(
                controller: _addressCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Street address, district'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Address is required' : null),
            const SizedBox(height: 20),
            _label('Contact Number'),
            TextFormField(
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration:
                    const InputDecoration(hintText: '+250 7XX XXX XXX')),
            const SizedBox(height: 20),
            _label('Description'),
            TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Describe this place or service...'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Description is required' : null),
            const SizedBox(height: 20),
            Row(children: [
              const Text('Geographic Coordinates',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: _isLocating ? null : _getLocation,
                icon: _isLocating
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.accentGold))
                    : const Icon(Icons.my_location,
                        size: 16, color: AppTheme.accentGold),
                label: const Text('Use Current'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextFormField(
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(hintText: 'Latitude'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final lat = double.tryParse(v);
                        if (lat == null) return 'Invalid';
                        if (lat < _minRwandaLat || lat > _maxRwandaLat) {
                          return 'Use Rwanda latitude';
                        }
                        return null;
                      })),
              const SizedBox(width: 12),
              Expanded(
                  child: TextFormField(
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(hintText: 'Longitude'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final lng = double.tryParse(v);
                        if (lng == null) return 'Invalid';
                        if (lng < _minRwandaLng || lng > _maxRwandaLng) {
                          return 'Use Rwanda longitude';
                        }
                        return null;
                      })),
            ]),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: Text(isEditing ? 'Update Listing' : 'Create Listing'),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
