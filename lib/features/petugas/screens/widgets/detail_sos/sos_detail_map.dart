import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


class SosDetailMap extends StatelessWidget {
  final LatLng center;
  final Color statusColor;
  final IconData jenisIcon;
  final Animation<double> pulseAnim;

  const SosDetailMap({
    super.key,
    required this.center,
    required this.statusColor,
    required this.jenisIcon,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft:  Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      child: SizedBox(
        height: 230,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.aegis.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 80,
                  height: 80,
                  child: AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, _) => Transform.scale(
                      scale: pulseAnim.value,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.55),
                                blurRadius: 14,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(jenisIcon,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}