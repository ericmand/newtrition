import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:barcode_scan/barcode_scan.dart';

import 'config.dart' as config; // Optional. Used to store keys

void main() => runApp(new FoodFactsApp());

class FoodFactsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new FoodFactsPage(),
    );
  }
}

class FoodFactsPage extends StatefulWidget {
  FoodFactsPage({Key key}) : super(key: key);
  @override
  _FoodFactsPageState createState() => new _FoodFactsPageState();
}

class _FoodFactsPageState extends State<FoodFactsPage> {
  var name = 'Food Facts';
  var water = 0.0;
  var protein = 0.0;
  var fat = 0.0;
  var carbs = 0.0;

  final GlobalKey<AnimatedCircularChartState> _macroChartKey =
  new GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _microChartKey =
  new GlobalKey<AnimatedCircularChartState>();

  List<CircularStackEntry> data = <CircularStackEntry>[
    new CircularStackEntry(
      <CircularSegmentEntry>[
        new CircularSegmentEntry(0.0, Colors.blue, rankKey: 'Water'),
        new CircularSegmentEntry(0.0, Colors.red, rankKey: 'Fat'),
        new CircularSegmentEntry(0.0, Colors.purple, rankKey: 'Protein'),
        new CircularSegmentEntry(0.0, Colors.yellow, rankKey: 'Carbs'),
      ],
      rankKey: 'Calorics',
    ),
  ];

  scan() async {
    String upc = await BarcodeScanner.scan();
    upcLookup(upc);
  }

  upcLookup(upc) async {
    var uri = new Uri.https('api.nal.usda.gov','/ndb/search/', {
      'q': upc,
      'format': 'json',
      'api_key': config.usdaApiKey // Use 'DEMO_KEY' for testing
    });
    var data = await getAPI(uri);
    ndbnoLookup(data['list']['item'][0]['ndbno']);
    if (!mounted) return;
  }

  ndbnoLookup(ndbno) async {
    var uri = new Uri.https('api.nal.usda.gov','/ndb/reports/', {
      'ndbno': ndbno,
      'format': 'json',
      'api_key': config.usdaApiKey // Use 'DEMO_KEY' for testing
    });
    var data = await getAPI(uri);
    setState(() {
      name = data['report']['food']['name'];
      for (var nutrient in data['report']['food']['nutrients']) {
        if (nutrient['name'] == 'Protein') {
          protein = double.parse(nutrient['value']);
        } else if (nutrient['name'] == 'Total lipid (fat)') {
          fat = double.parse(nutrient['value']);
        } else if (nutrient['name'] == 'Carbohydrate, by difference') {
          carbs = double.parse(nutrient['value']);
        } else if (nutrient['name'] == 'Water') {
          carbs = double.parse(nutrient['value']);
        }
      }
      water = 100 - carbs - protein - fat;
    });
    updateChart();
  }

  updateChart() {
    List<CircularStackEntry> nextData = <CircularStackEntry>[
      new CircularStackEntry(
        <CircularSegmentEntry>[
          new CircularSegmentEntry(fat, Colors.red, rankKey: 'Fat'),
          new CircularSegmentEntry(protein, Colors.purple, rankKey: 'Protien'),
          new CircularSegmentEntry(water, Colors.blue, rankKey: 'Water'),
          new CircularSegmentEntry(carbs, Colors.yellow, rankKey: 'Carbs'),
        ],
        rankKey: 'Calorics',
      ),
    ];
    setState(() {
      _macroChartKey.currentState.updateData(nextData);
    });
  }

  getAPI(uri) async {
    var httpClient = new HttpClient();
    String result;
    try{
      var request = await httpClient.getUrl(uri);
      var response = await request.close();
      if (response.statusCode == HttpStatus.OK) {
        var json = await response.transform(UTF8.decoder).join();
        return JSON.decode(json);
      } else {
        print(response.statusCode);
        return 'Error:\nHttp status ${response.statusCode}';
      }
    } catch (exception) {
      print(exception);
      result = 'Failed: $exception';
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(name),
        actions: [
          new IconButton(
            icon: new Icon(Icons.search),
            onPressed: () {},
          ),
        ]
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new AnimatedCircularChart(
              key: _macroChartKey,
              size: const Size(300.0, 300.0),
              initialChartData: data,
              chartType: CircularChartType.Radial,
            ),
            new AnimatedCircularChart(
              key: _microChartKey,
              size: const Size(300.0, 300.0),
              initialChartData: data,
              chartType: CircularChartType.Radial,
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
          child: new Icon(Icons.scanner),
          onPressed: scan,//_upc_lookup,
      ),
    );
  }
}