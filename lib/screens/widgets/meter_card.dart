import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_data_provider.dart';
import '../../models/meter_data.dart';

class MeterCard extends StatelessWidget {
  final String daireNo;
  final String isiEndeks;
  final String suEndeks;
  final bool isSuccess;

  const MeterCard({
    super.key,
    required this.daireNo,
    required this.isiEndeks,
    required this.suEndeks,
    this.isSuccess = true,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<AppDataProvider, ReadingMode>(
      selector: (_, p) => p.selectedReadingMode,
      builder: (context, mode, _) {
        bool calculatedSuccess = isSuccess;
        if (mode == ReadingMode.heat) {
      calculatedSuccess = isiEndeks != "Okunamadı" && isiEndeks.isNotEmpty;
    } else if (mode == ReadingMode.water) {
      calculatedSuccess = suEndeks != "Okunamadı" && suEndeks.isNotEmpty;
    } else if (mode == ReadingMode.both) {
      calculatedSuccess = (isiEndeks != "Okunamadı" && isiEndeks.isNotEmpty) &&
                          (suEndeks != "Okunamadı" && suEndeks.isNotEmpty);
    }

    const Color bgSurface = Color(0xFF1E293B);
    const Color borderColor = Color(0xFF334155);
    const Color textMain = Color(0xFFF8FAFC);
    const Color textMuted = Color(0xFF94A3B8);
    const Color accentGreen = Color(0xFF22C55E);
    const Color accentRed = Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.apartment, color: textMuted, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Daire $daireNo",
                    style: const TextStyle(
                      color: textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (calculatedSuccess ? accentGreen : accentRed).withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: calculatedSuccess ? accentGreen : accentRed,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      calculatedSuccess ? Icons.check_circle : Icons.error_outline,
                      color: calculatedSuccess ? accentGreen : accentRed,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      calculatedSuccess ? "Başarılı" : "Okunamadı",
                      style: TextStyle(
                        color: calculatedSuccess ? accentGreen : accentRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: borderColor, height: 1),
          ),

          Row(
            children: [
              if (mode == ReadingMode.heat || mode == ReadingMode.both)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orangeAccent,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "ISI SAYACI",
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isiEndeks,
                          style: const TextStyle(
                            color: textMain,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (mode == ReadingMode.both)
                Container(
                  height: 40,
                  width: 1,
                  color: borderColor,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),

              if (mode == ReadingMode.water || mode == ReadingMode.both)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            color: Colors.lightBlueAccent,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "SU SAYACI",
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          suEndeks,
                          style: const TextStyle(
                            color: textMain,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }
}
