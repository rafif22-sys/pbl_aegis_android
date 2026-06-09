import 'package:flutter/material.dart';
import '../../../models/tamu_model.dart';
import 'helpers.dart';

class GuestCard extends StatelessWidget {
  const GuestCard({
    super.key,
    required this.tamu,
    required this.showAllDates,
    required this.onTap,
  });

  final TamuModel tamu;
  final bool showAllDates;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final masuk = tamu.waktuMasuk.toLocal();
    final isKeluar = tamu.status == 'keluar';
    final today = DateTime.now();

    // --- TAMBAHAN LOGIKA OVERTIME ---
    final bool isBelumKeluar = !isKeluar;
    final bool hasWaktuKeluar = tamu.waktuKeluar != null;
    final bool isOvertime = isBelumKeluar && hasWaktuKeluar && today.isAfter(tamu.waktuKeluar!.toLocal());
    // ---------------------------------

    final masukBedaHari = masuk.year != today.year ||
        masuk.month != today.month ||
        masuk.day != today.day;

    String waktuMasukStr = (showAllDates || masukBedaHari)
        ? '${formatDateShort(masuk)} ${formatTime(masuk)}'
        : formatTime(masuk);

    // Waktu keluar
    String waktuKeluarStr = '--:--';
    if (hasWaktuKeluar) {
      final keluar = tamu.waktuKeluar!.toLocal();
      final bedaHari = keluar.year != masuk.year ||
          keluar.month != masuk.month ||
          keluar.day != masuk.day;

      waktuKeluarStr = bedaHari
          ? '${formatDateShort(keluar)} ${formatTime(keluar)}'
          : formatTime(keluar);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 12, right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              // --- TAMBAHAN BORDER MERAH JIKA OVERTIME ---
              border: Border.all(
                color: isOvertime ? Colors.red.shade300 : Colors.grey.shade200,
                width: isOvertime ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nama + Badge Status ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- TAMBAHAN BADGE OVERTIME DI SEBELAH NAMA ---
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              tamu.nama,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOvertime) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: const Text(
                                'OVERTIME!',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // ------------------------------------------------
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isKeluar
                            ? const Color(0xFFC8E6C9)
                            : const Color(0xFFBBDEFB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isKeluar ? 'Keluar' : 'Masuk',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // ── Waktu Masuk & Keluar + ID ──
                // --- UBAH JADI RICHTEXT AGAR BISA MERAH ---
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(text: 'Masuk $waktuMasukStr  |  '),
                      TextSpan(
                        text: 'Keluar $waktuKeluarStr',
                        style: TextStyle(
                          color: (!hasWaktuKeluar || isOvertime) ? Colors.red : Colors.grey,
                          fontWeight: (!hasWaktuKeluar || isOvertime) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                // ------------------------------------------
              ],
            ),
          ),
        ),
      ),
    );
  }
}