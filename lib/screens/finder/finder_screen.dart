import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class FinderScreen extends StatefulWidget {
  const FinderScreen({super.key});

  @override
  State<FinderScreen> createState() => _FinderScreenState();
}

class _FinderScreenState extends State<FinderScreen> {
  String selectedFilter = "All";

  final List<Map<String, dynamic>> services = [
    {
      "name": "Test Driver",
      "type": "Van",
      "price": "Rs. 0.0",
      "rating": "5.0"
    },

    {
      "name": "Nimal Perera",
      "type": "Mini Bus",
      "price": "Rs. 4500",
      "rating": "4.9"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F6FA),
        title: const Text(
          "Find a service",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLocationCard(),
            const SizedBox(height: 20),
            _buildFilterSection(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: services
                    .where((service) =>
                        selectedFilter == "All" ||
                        service["type"] == selectedFilter)
                    .map((service) => _buildServiceCard(service))
                    .toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 🔹 Location Card
  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.radio_button_checked,
                  color: Colors.green, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Home - Bambalapitiya",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.swap_vert),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.location_on, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Royal Primary School",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Filter Chips
  Widget _buildFilterSection() {
    final filters = ["All", "Van", "Mini Bus"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map((filter) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedFilter == filter
                            ? const Color(0xFF2D2F55)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          if (selectedFilter != filter)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                            )
                        ],
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: selectedFilter == filter
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // 🔹 Service Card
  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8EBFF),
            child: Text(
              service["name"][0],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2F55),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service["name"],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service["type"],
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(service["rating"]),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                service["price"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2F55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                onPressed: () {},
                child: const Text("Details"),
              ),
            ],
          )
        ],
      ),
    );
  }
}