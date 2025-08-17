





/************************************  code that shows proper frontend and navigation but dont show direction in  map */

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class EVChargingScreen extends StatefulWidget {
  const EVChargingScreen({super.key});

  @override
  State<EVChargingScreen> createState() => _EVChargingScreenState();
}

class _EVChargingScreenState extends State<EVChargingScreen> {
  late GoogleMapController mapController;
  LatLng _center = const LatLng(12.9716, 77.5946);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Position? _currentPosition;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _chargingStations = [];
  bool _showMap = false;
  String _locationMessage = '';

  final List<Map<String, dynamic>> _allStations = [
    {
      "name": "Ravi's home charging",
      "rating": 4.5,
      "distance": 0.4,
      "availableTime": "Available 24/7",
      "capacity": "7KW",
      "price": "₹8/KWh",
      "latitude": 12.9716,
      "longitude": 77.5946,
    },
    {
      "name": "Green Society Hub",
      "rating": 4.2,
      "distance": 0.8,
      "availableTime": "6AM - 11PM",
      "capacity": "10KW",
      "price": "₹10/KWh",
      "latitude": 12.9756,
      "longitude": 77.5956,
    },
    {
      "name": "Express Charging Point",
      "rating": 4.7,
      "distance": 1.2,
      "availableTime": "7AM - 10PM",
      "capacity": "50KW",
      "price": "₹15/KWh",
      "latitude": 12.9686,
      "longitude": 77.5936,
    },
  ];

  @override
  void initState() {
    super.initState();
    _chargingStations = _allStations;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = 'Location services are disabled.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = 'Location permissions are permanently denied';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationMessage = 'Location fetched successfully!';
        _updateDistances(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() {
        _locationMessage = 'Error getting location: $e';
      });
    }
  }

  void _updateDistances(double userLat, double userLng) {
    setState(() {
      _chargingStations = _allStations.map((station) {
        double distance = Geolocator.distanceBetween(
          userLat, userLng, station['latitude'], station['longitude']
        ) / 1000;
        return {...station, 'distance': double.parse(distance.toStringAsFixed(1))};
      }).toList();
      _chargingStations.sort((a, b) => a['distance'].compareTo(b['distance']));
    });
  }

  void _showDirections(LatLng destination) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine current location')));
      return;
    }

    setState(() {
      _showMap = true;
      _center = destination;
      _markers.clear();
      _polylines.clear();
      
      // Add current location marker
      _markers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
      
      // Add destination marker
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        infoWindow: const InfoWindow(title: 'Charging Station'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    });

    // Get the route between current location and destination
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyB82H7s8dM-Z9v5E_3HIl301m0iM3e6ctc', // Replace with your API key
      PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));
      });

      // Adjust camera to show both locations and route
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          min(_currentPosition!.latitude, destination.latitude),
          min(_currentPosition!.longitude, destination.longitude),
        ),
        northeast: LatLng(
          max(_currentPosition!.latitude, destination.latitude),
          max(_currentPosition!.longitude, destination.longitude),
        ),
      );
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  void _searchStations(String query) {
    setState(() {
      _chargingStations = query.isEmpty 
          ? _allStations 
          : _allStations.where((station) => 
              station['name'].toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Charging Stations'),
        backgroundColor: const Color(0xFF706DC7),
      ),
      body: _showMap ? _buildMapView() : _buildListView(),
    );
  }

  Widget _buildListView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for charging stations...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchStations,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _getCurrentLocation,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0DFF6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: Color(0xFF706DC7)),
                    const SizedBox(width: 10),
                    Text(_locationMessage.isEmpty 
                        ? 'Use current location' 
                        : _locationMessage),
                  ],
                ),
              ),
            ),
          ),
          if (_currentPosition != null) ...[
            const SizedBox(height: 10),
            Text(
              'Your location: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
              '${_currentPosition!.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Nearby providers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sort by:'),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _chargingStations.sort((a, b) => a['distance'].compareTo(b['distance']));
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text('Distance'),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _chargingStations.sort((a, b) => b['rating'].compareTo(a['rating']));
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text('Rating'),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._chargingStations.map((station) => Column(
            children: [
              _buildStationCard(station),
              const SizedBox(height: 15),
            ],
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildStationCard(Map<String, dynamic> station) {
    return GestureDetector(
      onTap: () {
        _showDirections(LatLng(station['latitude'], station['longitude']));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    station['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(station['rating'].toString()),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${station['distance'].toStringAsFixed(1)} km distance away'),
              const SizedBox(height: 8),
              Text('Available: ${station['availableTime']}'),
              const SizedBox(height: 8),
              Text('Capacity: ${station['capacity']}'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    station['price'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF706DC7),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/booking',
                        arguments: station,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF706DC7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _showMap = false;
              });
            },
            child: const Text('Back to List'),
          ),
        ),
      ],
    );
  }
}

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final station = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: const Color(0xFF706DC7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Capacity: ${station['capacity']}'),
            Text('Price: ${station['price']}'),
            Text('Availability: ${station['availableTime']}'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final url = 'https://www.google.com/maps/dir/?api=1&destination=${station['latitude']},${station['longitude']}';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch maps')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF706DC7),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Get Directions',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


















































/****************************   code that shows map *******************************/


// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:math';

// class EVChargingScreen extends StatefulWidget {
//   const EVChargingScreen({super.key});

//   @override
//   State<EVChargingScreen> createState() => _EVChargingScreenState();
// }

// class _EVChargingScreenState extends State<EVChargingScreen> {
//   late GoogleMapController mapController;
//   LatLng _center = const LatLng(12.9716, 77.5946);
//   final Set<Marker> _markers = {};
//   final Set<Polyline> _polylines = {};
//   Position? _currentPosition;
//   final TextEditingController _searchController = TextEditingController();
//   List<Map<String, dynamic>> _chargingStations = [];
//   final List<Map<String, dynamic>> _allStations = [
//     {
//       "name": "Ravi's home charging",
//       "rating": 4.5,
//       "distance": 0.4,
//       "availableTime": "Available 24/7",
//       "capacity": "7KW",
//       "price": "₹8/KWh",
//       "latitude": 12.9716,
//       "longitude": 77.5946,
//     },
//     {
//       "name": "Green Society Hub",
//       "rating": 4.2,
//       "distance": 0.8,
//       "availableTime": "6AM - 11PM",
//       "capacity": "10KW",
//       "price": "₹10/KWh",
//       "latitude": 12.9756,
//       "longitude": 77.5956,
//     },
//     {
//       "name": "Express Charging Point",
//       "rating": 4.7,
//       "distance": 1.2,
//       "availableTime": "7AM - 10PM",
//       "capacity": "50KW",
//       "price": "₹15/KWh",
//       "latitude": 12.9686,
//       "longitude": 77.5936,
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _chargingStations = _allStations;
//     _getCurrentLocation();
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     mapController = controller;
//   }

//   void _getCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) return;
//     }

//     Position position = await Geolocator.getCurrentPosition();
//     setState(() {
//       _currentPosition = position;
//       _center = LatLng(position.latitude, position.longitude);
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('currentLocation'),
//           position: LatLng(position.latitude, position.longitude),
//           infoWindow: const InfoWindow(title: 'Your Location'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//         ),
//       );
//       _updateDistances(position.latitude, position.longitude);
//     });
//   }

//   void _updateDistances(double userLat, double userLng) {
//     setState(() {
//       _chargingStations = _allStations.map((station) {
//         double distance = Geolocator.distanceBetween(
//           userLat, userLng, station['latitude'], station['longitude']
//         ) / 1000;
//         return {...station, 'distance': double.parse(distance.toStringAsFixed(1))};
//       }).toList();
//       _chargingStations.sort((a, b) => a['distance'].compareTo(b['distance']));
//     });
//   }

//   void _showDirections(LatLng destination) async {
//     if (_currentPosition == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Could not determine current location')));
//       return;
//     }

//     PolylinePoints polylinePoints = PolylinePoints();
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       'AIzaSyB82H7s8dM-Z9v5E_3HIl301m0iM3e6ctc', // Replace with your API key
//       PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//       PointLatLng(destination.latitude, destination.longitude),
//       travelMode: TravelMode.driving,
//     );

//     if (result.points.isNotEmpty) {
//       List<LatLng> polylineCoordinates = result.points
//           .map((point) => LatLng(point.latitude, point.longitude))
//           .toList();

//       setState(() {
//         _polylines.add(Polyline(
//           polylineId: const PolylineId('route'),
//           points: polylineCoordinates,
//           color: Colors.blue,
//           width: 5,
//         ));
//         _markers.add(Marker(
//           markerId: const MarkerId('destination'),
//           position: destination,
//           infoWindow: const InfoWindow(title: 'Charging Station'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//         ));
//       });

//       mapController.animateCamera(CameraUpdate.newLatLngBounds(
//         LatLngBounds(
//           southwest: LatLng(
//             min(_currentPosition!.latitude, destination.latitude),
//             min(_currentPosition!.longitude, destination.longitude),
//           ),
//           northeast: LatLng(
//             max(_currentPosition!.latitude, destination.latitude),
//             max(_currentPosition!.longitude, destination.longitude),
//           ),
//         ),
//         50,
//       ));
//     }
//   }

//   void _searchStations(String query) {
//     setState(() {
//       _chargingStations = query.isEmpty 
//           ? _allStations 
//           : _allStations.where((station) => 
//               station['name'].toLowerCase().contains(query.toLowerCase()))
//               .toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('EV Charging Stations'),
//         backgroundColor: const Color(0xFF706DC7),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search for charging stations...',
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.search),
//                   onPressed: () {
//                     LatLng demoStation = const LatLng(12.9756, 77.5995);
//                     _showDirections(demoStation);
//                   },
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               onChanged: _searchStations,
//             ),
//           ),
//           Expanded(
//             child: GoogleMap(
//               onMapCreated: _onMapCreated,
//               initialCameraPosition: CameraPosition(
//                 target: _center,
//                 zoom: 14.0,
//               ),
//               markers: _markers,
//               polylines: _polylines,
//               myLocationEnabled: true,
//               myLocationButtonEnabled: true,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class BookingScreen extends StatelessWidget {
//   const BookingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final station = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Booking Details'),
//         backgroundColor: const Color(0xFF706DC7),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               station['name'],
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             Text('Capacity: ${station['capacity']}'),
//             Text('Price: ${station['price']}'),
//             Text('Availability: ${station['availableTime']}'),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: () async {
//                 final url = 'https://www.google.com/maps/dir/?api=1&destination=${station['latitude']},${station['longitude']}';
//                 if (await canLaunchUrl(Uri.parse(url))) {
//                   await launchUrl(Uri.parse(url));
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Could not launch maps')),
//                   );
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF706DC7),
//                 minimumSize: const Size(double.infinity, 50),
//               ),
//               child: const Text(
//                 'Get Directions',
//                 style: TextStyle(fontSize: 18),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }