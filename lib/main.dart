import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';

void main() {
  runApp(new MyApp());
}

// Scanner output UPC codes
// UPC fetch:
  // input: UPC, outputs: ndbno
  // data['list']['item'][0]['ndbno']
// input: ndbno, outputs: food object that contains the 10 numbers

// Text search input string text
// input: string, output: list of foods that relates
// input: ndbno, output: food object



class Food {
  String name;
  int water;
  int protein;
  int fat;
  int carbs;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _ipAddress = 'Unknown';

  final GlobalKey<AnimatedCircularChartState> _chartKey =
  new GlobalKey<AnimatedCircularChartState>();

  List<CircularStackEntry> data = <CircularStackEntry>[
    new CircularStackEntry(
      <CircularSegmentEntry>[
        new CircularSegmentEntry(500.0, Colors.blue[200], rankKey: 'Water'),
        new CircularSegmentEntry(1000.0, Colors.red[200], rankKey: 'Fat'),
        new CircularSegmentEntry(2000.0, Colors.green[200], rankKey: 'Protein'),
        new CircularSegmentEntry(1000.0, Colors.yellow[200], rankKey: 'Carbs'),
      ],
      rankKey: 'Quarterly Profits',
    ),
  ];

  void _cycleSamples() {
    List<CircularStackEntry> nextData = <CircularStackEntry>[
      new CircularStackEntry(
        <CircularSegmentEntry>[
          new CircularSegmentEntry(1500.0, Colors.red[200], rankKey: 'Q1'),
          new CircularSegmentEntry(750.0, Colors.green[200], rankKey: 'Q2'),
          new CircularSegmentEntry(2000.0, Colors.blue[200], rankKey: 'Q3'),
          new CircularSegmentEntry(1000.0, Colors.yellow[200], rankKey: 'Q4'),
        ],
        rankKey: 'Quarterly Profits',
      ),
    ];
    setState(() {
      _chartKey.currentState.updateData(nextData);
    });
  }

  _upc_lookup(upc) {
    var data = _upc_fetch(upc);
    print(data);
    setState(() {
      _ipAddress = data.toString();
    });
    //return data //['list']['item'][0]['ndbno'];
  }

  _upc_fetch(upc) async {
    var uri = new Uri.https('api.nal.usda.gov','/ndb/search/', {
      'q': '791083622813',
      'format': 'json',
      'api_key': 'RCnEQqU9pmNEbaEzE5SQxQQ1VHbDZhQJYCvzAOkJ',
    });
    var httpClient = new HttpClient();

    String result;
    var request = await httpClient.getUrl(uri);//Uri.parse(url));
    var response = await request.close();
    if (response.statusCode == HttpStatus.OK) {
      var json = await response.transform(UTF8.decoder).join();
      return JSON.decode(json);
    } else { return 'fail';}
  }

  _getIPAddress() async {
    //var url = 'https://api.nal.usda.gov/ndb/reports/?ndbno=01009&type=f&format=json&api_key=DEMO_KEY';
    var uri = new Uri.https('api.nal.usda.gov','/ndb/reports/', {
      'ndbno': '01009',
      'format': 'json',
      'type': 'f',
      'api_key': 'DEMO_KEY',//'RCnEQqU9pmNEbaEzE5SQxQQ1VHbDZhQJYCvzAOkJ',
    });
    var httpClient = new HttpClient();

    String result;
    try {
      var request = await httpClient.getUrl(uri);//Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.OK) {
        var json = await response.transform(UTF8.decoder).join();
        var data = JSON.decode(json);
        result = data['report']['food']['nutrients'][0]['name'];
      } else {

        result =
        'Error getting IP address:\nHttp status ${response.statusCode}';
      }
    } catch (exception) {
      print(exception);
      result = 'Failed getting IP address';
    }

    // If the widget was removed from the tree while the message was in flight,
    // we want to discard the reply rather than calling setState to update our
    // non-existent appearance.
    if (!mounted) return;

    setState(() {
      _ipAddress = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    var spacer = new SizedBox(height: 32.0);

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Food Facts'),
        actions: [
          new IconButton( // action button
            icon: new Icon(Icons.search),
            onPressed: () {},
          ),
        ]
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new Text('$_ipAddress.'),
            spacer,
            new RaisedButton(
              onPressed: _cycleSamples,
              child: new Text('Get IP address'),
            ),
            new AnimatedCircularChart(
              key: _chartKey,
              size: const Size(300.0, 300.0),
              initialChartData: data,
              chartType: CircularChartType.Pie,
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
          child: new Icon(Icons.scanner),
          onPressed: _upc_lookup('791083622813'),
      ),
    );
  }
}

/*
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Food Facts',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new ButtonPage(),
    );
  }
}

Future scan() async {
  String barcode = await BarcodeScanner.scan();
  //setState(() => this.barcode = barcode);
}

get() async {
  var httpClient = new HttpClient();
  var uri = new Uri.http(
      'example.com', '/path1/path2', {'param1': '42', 'param2': 'foo'});
  var request = await httpClient.getUrl(uri);
  var response = await request.close();
  var responseBody = await response.transform(UTF8.decoder).join();
}

Future getListFoods() async {
  var httpClient = new HttpClient();
  var uri = new Uri.https('api.nal.usda.gov','/ndb/search', {
    //'http://example.com/', 'path1/path2', {'param1': '42', 'param2': 'foo'});
    'format': 'json',
    'q': 'query',
    'sort': 'n',
    'max': '25',
    'offset': '0',
    'api_key': 'RCnEQqU9pmNEbaEzE5SQxQQ1VHbDZhQJYCvzAOkJ'
  });
  var request = await httpClient.getUrl(uri);
  var response = await request.close();
  var responseBody = await response.transform(UTF8.decoder).join();
}

Future getFoodDetails() async {
  var httpClient = new HttpClient();
  var uri = new Uri.https('api.nal.usda.gov','/ndb/v2/reports', {
    'ndbno': '01009',
    'format': 'json',
    'type': 'f',
    'api_key': 'RCnEQqU9pmNEbaEzE5SQxQQ1VHbDZhQJYCvzAOkJ'
  });
  var request = await httpClient.getUrl(uri);
  var response = await request.close();
  var responseBody = await response.transform(UTF8.decoder).join();
  print(responseBody);
}

search() {
  var item = getFoodDetails();
}
//https://api.nal.usda.gov/ndb/V2/reports?ndbno=01009&ndbno=45202763&ndbno=35193&type=f&format=json&api_key=DEMO_KEY

class ButtonPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Food Facts'),
      ),
      body: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          new Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              new RaisedButton(
                onPressed: scan,
                child: new Text('Scan'),
              ),
              new RaisedButton(
                onPressed: search,//('n5258948'),
                child: new Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
*/
