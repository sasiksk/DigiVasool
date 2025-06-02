import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DateSumBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool showCredit; // true: show CrAmt, false: show DrAmt

  const DateSumBarChart(
      {super.key, required this.data, this.showCredit = true});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data for selected range'));
    }
    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: List.generate(data.length, (i) {
            final item = data[i];
            final value = showCredit
                ? (item['totalCrAmt'] as num?) ?? 0
                : (item['totalDrAmt'] as num?) ?? 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value.toDouble(),
                  color: showCredit ? Colors.green : Colors.red,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  final date = data[idx]['Date'] as String;
                  return Text(date.substring(5),
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }
}
