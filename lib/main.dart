import 'dart:ffi';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FilePickerResult? result;
  PlatformFile? file;
  String filePath = "";
  String productRequest = '';
  List<List<dynamic>> dataCSV = [];
  List<List<dynamic>> dataRequest = [];
  int csvLength = 0;
  final _textController = TextEditingController();
  String _countdown = '0';
  late Timer _timer;
  int _counter = 0;

  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
    });
  }

  Future<void> loadCSV() async {
    final _rawData = await rootBundle.loadString("assets/csv.csv");
    List<List<dynamic>> _listData =
        const CsvToListConverter().convert(_rawData);
    setState(() {
      dataCSV = _listData;
    });
  }

  Future<void> _startCountdown() async {s
    setState(() {
      _countdown = _textController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 100.0, vertical: 20.0),
        child: Column(
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: Image.asset('assets/logo.png'),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Product Request',
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(color: Colors.black54),
                      suffixIcon: Tooltip(
                        message: 'Lorem ipsum dolor sit amet',
                        child: Icon(Icons.info),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        productRequest = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(right: 670),
                    child: TextField(
                      // ignore: prefer_const_constructors
                      decoration: InputDecoration(
                        labelText: 'Tempo',
                        hintText: 'Tempo entre cada comentário em segundos',
                        border: const OutlineInputBorder(),
                        hintStyle: const TextStyle(color: Colors.black54),
                      ),
                      controller: _textController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowMultiple: false,
                          allowedExtensions: ['csv'],
                        );
                        file = result!.files.first;
                        setState(() {
                          filePath = file!.path.toString();
                        });
                      },
                      child: Text(
                        'Selecionar Arquivo',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Text(filePath),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (dataCSV != []) {
                    await loadCSV();
                    csvLength = dataCSV.length;
                    final shopInfo = ShopModel.fromMap(
                      json.decode(productRequest),
                    );
                    for (int i = 0; i < dataCSV.length; i++) {
                      final review = ReviewModel(
                        rating: dataCSV[i][0].toInt(),
                        name: dataCSV[i][1].toString(),
                        email: dataCSV[i][2].toString(),
                        title: dataCSV[i][3].toString(),
                        content: dataCSV[i][4].toString(),
                        imgProduct: shopInfo.imgProduct,
                        titleProduct: shopInfo.titleProduct,
                      );
                      await _startCountdown();
                      await addComent(review: review, shopInfo: shopInfo);
                      await _incrementCounter();

                      await Future.delayed(Duration(
                          seconds: int.parse(_countdown))); //TODO(LUCAS): TIMER
                    }
                  }
                },
                child: Text(
                  'COMENTAR',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Column(
              children: [
                Text(
                  '$_counter/$csvLength',
                  style: GoogleFonts.montserrat(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
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

Future<bool> addComent({
  required ReviewModel review,
  required ShopModel shopInfo,
}) async {
  try {
    final result = await Dio().post(
      "https://app.ryviu.io/frontend/client/customer-write-review?domain=${shopInfo.domain}",
      data: json.encode(
        {
          "shopInfo": shopInfo.toMap(),
          "reviewData": review.toMap(),
          "files": [],
          "platform": "shopify"
        },
      ),
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    print(result.statusCode);
    return true;
  } catch (e) {
    print(e);
    rethrow;
  }
}

class ReviewModel {
  final String name;
  final String title;
  final String content;
  final int rating;
  final String email;
  final String imgProduct;
  final String titleProduct;

  ReviewModel({
    required this.name,
    required this.title,
    required this.content,
    required this.rating,
    required this.email,
    required this.imgProduct,
    required this.titleProduct,
  });

  toMap() {
    return json.encode(
      {
        "rating": rating,
        "cname": name,
        "cemail": email,
        "ctitle": title,
        "ccontent": content,
        "img_urls": [],
        "title_product": titleProduct,
        "image_product": imgProduct,
      },
    );
  }
}

class ShopModel {
  final String domain;
  final String handle;
  final int productId;
  final String titleProduct;
  final String imgProduct;

  ShopModel({
    required this.domain,
    required this.handle,
    required this.productId,
    required this.titleProduct,
    required this.imgProduct,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    final shopInfo = json.decode(map['shopInfo']);
    final reviewData = json.decode(map['reviewData']);
    return ShopModel(
      domain: shopInfo['domain'],
      handle: shopInfo['handle'],
      productId: shopInfo['product_id'],
      titleProduct: reviewData['title_product'],
      imgProduct: reviewData['image_product'],
    );
  }

  toMap() {
    return json.encode({
      "domain": domain,
      "handle": handle,
      "product_id": productId,
    });
  }
}
