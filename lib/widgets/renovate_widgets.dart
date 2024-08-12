import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class RenovateWidget extends StatefulWidget {
  const RenovateWidget({Key? key}) : super(key: key);

  @override
  _RenovateWidgetState createState() => _RenovateWidgetState();
}

class _RenovateWidgetState extends State<RenovateWidget> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Future<List<dynamic>> _fetchRenovations() async {
    try {
      final response = await http.post(
        Uri.parse('https://apiglobex.tecno-prog.com/api/v1/mobile/renovate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'cmes': _selectedMonth,
          'cano': _selectedYear,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        if (data['status'] == true) {
          return data['renovate'] as List<dynamic>;
        } else {
          throw Exception('Error en la respuesta de la API');
        }
      } else {
        throw Exception('Error al obtener datos de renovación: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Color.fromRGBO(39, 144, 214, 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Text(
              'Renovaciones',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text('Mes ${index + 1}'),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value!;
                        _fetchRenovations(); // Consultar la API cuando cambie el mes
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    items: List.generate(10, (index) {
                      final year = 2024 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value!;
                        _fetchRenovations(); // Consultar la API cuando cambie el año
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _fetchRenovations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final hasData = snapshot.hasData && snapshot.data != null;
              final renovateData = hasData ? snapshot.data! : [];

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    renovateData.isNotEmpty
                        ? SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: false, // Oculta los títulos en el eje izquierdo
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        return Text('Sem. ${index}');
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: false, // Oculta los títulos en el eje superior
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _prepareChartData(renovateData),
                              ),
                            ),
                          )
                        : Center(child: Text('No hay datos de renovación.')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _prepareChartData(List<dynamic> data) {
    return data.map((item) {
      final semana = item['semana'];
      final cantidad = item['cantidad'] as int;

      // Extraemos el número de la semana para usarlo como el índice en el gráfico
      final weekNumber = int.tryParse(semana.split(' ')[1]) ?? 0;

      return BarChartGroupData(
        x: weekNumber,
        barRods: [
          BarChartRodData(
            toY: cantidad.toDouble(),
            color: Colors.blue,
          ),
        ],
      );
    }).toList();
  }
}
