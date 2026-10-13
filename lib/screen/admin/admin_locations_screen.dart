import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/models/delivery_location.dart';
import 'package:bakehub/services/location_service.dart';
import 'package:bakehub/widgets/custom_text_field.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  final LocationService _locationService = LocationService.instance;
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final adminId = _firebaseAuth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLocationDialog(adminId),
            tooltip: 'Add Location',
          ),
        ],
      ),
      body: StreamBuilder<List<DeliveryLocation>>(
        stream: _locationService.getLocationsByAdmin(adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final locations = snapshot.data ?? [];

          if (locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No delivery locations yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first location',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return _buildLocationCard(location, adminId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLocationDialog(adminId),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text(
          'Add Location',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLocationCard(DeliveryLocation location, String adminId) {
    final isActive = location.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.1)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            color: isActive ? AppColors.primary : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                location.locationName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_city, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location.fullAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.pin_drop, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditLocationDialog(location, adminId);
                break;
              case 'toggle':
                _toggleLocationStatus(location);
                break;
              case 'delete':
                _showDeleteLocationConfirmation(location);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    location.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(location.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLocationDialog(String adminId) {
    final locationNameController = TextEditingController();
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final pinCodeController = TextEditingController();
    final landmarkController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool isLoading = false;
    bool isFetchingLocation = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Delivery Location'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: locationNameController,
                    label: 'Location Name',
                    hint: 'e.g., Downtown Area, Suburb East',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isFetchingLocation
                          ? null
                          : () async {
                              setState(() => isFetchingLocation = true);
                              try {
                                final permission =
                                    await Permission.location.status;
                                if (permission.isDenied) {
                                  final result = await Permission.location
                                      .request();
                                  if (!result.isGranted) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Location permission required',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    setState(() => isFetchingLocation = false);
                                    return;
                                  }
                                }

                                bool serviceEnabled =
                                    await Geolocator.isLocationServiceEnabled();
                                if (!serviceEnabled) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enable location services',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  setState(() => isFetchingLocation = false);
                                  return;
                                }

                                Position position =
                                    await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high,
                                    );

                                latitudeController.text = position.latitude
                                    .toStringAsFixed(6);
                                longitudeController.text = position.longitude
                                    .toStringAsFixed(6);

                                try {
                                  List<Placemark> placemarks =
                                      await placemarkFromCoordinates(
                                        position.latitude,
                                        position.longitude,
                                      );

                                  if (placemarks.isNotEmpty) {
                                    final place = placemarks.first;

                                    if (place.street != null &&
                                        place.street!.isNotEmpty) {
                                      streetController.text = place.street!;
                                    } else if (place.subLocality != null &&
                                        place.subLocality!.isNotEmpty) {
                                      streetController.text =
                                          place.subLocality!;
                                    }

                                    if (place.locality != null &&
                                        place.locality!.isNotEmpty) {
                                      cityController.text = place.locality!;
                                    }

                                    if (place.administrativeArea != null &&
                                        place.administrativeArea!.isNotEmpty) {
                                      stateController.text =
                                          place.administrativeArea!;
                                    }

                                    if (place.postalCode != null &&
                                        place.postalCode!.isNotEmpty) {
                                      pinCodeController.text =
                                          place.postalCode!;
                                    }

                                    if (place.subLocality != null &&
                                        place.subLocality!.isNotEmpty) {
                                      landmarkController.text =
                                          place.subLocality!;
                                    }
                                  }
                                } catch (e) {
                                  print('Reverse geocoding error: $e');
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Location fetched successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error getting location: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to get location'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                setState(() => isFetchingLocation = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      icon: isFetchingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.my_location, size: 20),
                      label: Text(
                        isFetchingLocation
                            ? 'Fetching...'
                            : 'Use Current Location',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: streetController,
                    label: 'Street Address',
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter street address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: cityController,
                    label: 'City',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: stateController,
                          label: 'State',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: pinCodeController,
                          label: 'PIN Code',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (value.length != 6) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: landmarkController,
                    label: 'Landmark (Optional)',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: latitudeController,
                          label: 'Latitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: longitudeController,
                          label: 'Longitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        try {
                          final location = DeliveryLocation(
                            id: '',
                            adminId: adminId,
                            locationName: locationNameController.text.trim(),
                            street: streetController.text.trim(),
                            city: cityController.text.trim(),
                            state: stateController.text.trim(),
                            pinCode: pinCodeController.text.trim(),
                            landmark: landmarkController.text.trim().isEmpty
                                ? null
                                : landmarkController.text.trim(),
                            latitude: double.parse(latitudeController.text),
                            longitude: double.parse(longitudeController.text),
                            isActive: true,
                            createdAt: DateTime.now(),
                          );

                          await _locationService.createLocation(location);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Location added successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLocationDialog(DeliveryLocation location, String adminId) {
    final locationNameController = TextEditingController(
      text: location.locationName,
    );
    final streetController = TextEditingController(text: location.street);
    final cityController = TextEditingController(text: location.city);
    final stateController = TextEditingController(text: location.state);
    final pinCodeController = TextEditingController(text: location.pinCode);
    final landmarkController = TextEditingController(text: location.landmark);
    final latitudeController = TextEditingController(
      text: location.latitude.toStringAsFixed(6),
    );
    final longitudeController = TextEditingController(
      text: location.longitude.toStringAsFixed(6),
    );
    final formKey = GlobalKey<FormState>();

    bool isLoading = false;
    bool isFetchingLocation = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Location'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: locationNameController,
                    label: 'Location Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isFetchingLocation
                          ? null
                          : () async {
                              setState(() => isFetchingLocation = true);
                              try {
                                final permission =
                                    await Permission.location.status;
                                if (permission.isDenied) {
                                  final result = await Permission.location
                                      .request();
                                  if (!result.isGranted) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Location permission required',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    setState(() => isFetchingLocation = false);
                                    return;
                                  }
                                }

                                bool serviceEnabled =
                                    await Geolocator.isLocationServiceEnabled();
                                if (!serviceEnabled) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enable location services',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  setState(() => isFetchingLocation = false);
                                  return;
                                }

                                Position position =
                                    await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high,
                                    );

                                latitudeController.text = position.latitude
                                    .toStringAsFixed(6);
                                longitudeController.text = position.longitude
                                    .toStringAsFixed(6);

                                try {
                                  List<Placemark> placemarks =
                                      await placemarkFromCoordinates(
                                        position.latitude,
                                        position.longitude,
                                      );

                                  if (placemarks.isNotEmpty) {
                                    final place = placemarks.first;

                                    if (place.street != null &&
                                        place.street!.isNotEmpty) {
                                      streetController.text = place.street!;
                                    } else if (place.subLocality != null &&
                                        place.subLocality!.isNotEmpty) {
                                      streetController.text =
                                          place.subLocality!;
                                    }

                                    if (place.locality != null &&
                                        place.locality!.isNotEmpty) {
                                      cityController.text = place.locality!;
                                    }

                                    if (place.administrativeArea != null &&
                                        place.administrativeArea!.isNotEmpty) {
                                      stateController.text =
                                          place.administrativeArea!;
                                    }

                                    if (place.postalCode != null &&
                                        place.postalCode!.isNotEmpty) {
                                      pinCodeController.text =
                                          place.postalCode!;
                                    }

                                    if (place.subLocality != null &&
                                        place.subLocality!.isNotEmpty) {
                                      landmarkController.text =
                                          place.subLocality!;
                                    }
                                  }
                                } catch (e) {
                                  print('Reverse geocoding error: $e');
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Location fetched successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error getting location: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to get location'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                setState(() => isFetchingLocation = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      icon: isFetchingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.my_location, size: 20),
                      label: Text(
                        isFetchingLocation
                            ? 'Fetching...'
                            : 'Use Current Location',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: streetController,
                    label: 'Street Address',
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter street address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: cityController,
                    label: 'City',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: stateController,
                          label: 'State',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: pinCodeController,
                          label: 'PIN Code',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (value.length != 6) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: landmarkController,
                    label: 'Landmark (Optional)',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: latitudeController,
                          label: 'Latitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: longitudeController,
                          label: 'Longitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        try {
                          await _locationService.updateLocation(location.id, {
                            'locationName': locationNameController.text.trim(),
                            'street': streetController.text.trim(),
                            'city': cityController.text.trim(),
                            'state': stateController.text.trim(),
                            'pinCode': pinCodeController.text.trim(),
                            'landmark': landmarkController.text.trim().isEmpty
                                ? null
                                : landmarkController.text.trim(),
                            'latitude': double.parse(latitudeController.text),
                            'longitude': double.parse(longitudeController.text),
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Location updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLocationStatus(DeliveryLocation location) async {
    try {
      await _locationService.toggleLocationStatus(
        location.id,
        !location.isActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location ${!location.isActive ? "activated" : "deactivated"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteLocationConfirmation(
    DeliveryLocation location,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text(
          'Are you sure you want to delete "${location.locationName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _locationService.deleteLocation(location.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
