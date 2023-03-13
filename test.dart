import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> productRequestJson = {
    "shopInfo":
        "{\"domain\":\"lukha-lar.myshopify.com\",\"handle\":\"frascosplantex\",\"product_id\":8036008263977}",
    "reviewData":
        "{\"rating\":5,\"cname\":\"Carlos Silveira \",\"cemail\":\"carlos.s@gmail.com\",\"ctitle\":\"Amei o produto!\",\"ccontent\":\"Recomendo muito a compra\",\"img_urls\":[],\"title_product\":\"Frascos de Plantas Minimalista\",\"image_product\":\"//cdn.shopify.com/s/files/1/0685/5504/7209/products/S3501674da34848b7913c8f7de38761b6X_100x.jpg?v=1670521704\"}",
    "files": [],
    "platform": "shopify"
  };
  test(
    'adicionar comentario',
    () async {
      await addComent(
          rating: '5',
          name: 'Rudyer Delgado',
          email: "rud.del@gmail.com",
          content: 'Recomendo esse produto para todos os meus familiares',
          title: 'Amei o produto e super recomendo',
          prdRequest: productRequestJson);
    },
  );
}

Future<bool> addComent(
    {required String name,
    required String title,
    required String content,
    required String email,
    required String rating,
    required Map<String, dynamic> prdRequest}) async {
  Map<String, dynamic> shopInfo = json.decode(prdRequest['shopInfo']);
  Map<String, dynamic> reviewData = json.decode(prdRequest['reviewData']);
  reviewData['rating'] = rating;
  reviewData['cname'] = name;
  reviewData['cemail'] = email;
  reviewData['ctitle'] = title;
  reviewData['ccontent'] = content;
  String site = shopInfo['domain'];
  try {
    final result = await Dio().post(
      "https://app.ryviu.io/frontend/client/customer-write-review?domain=$site",
      data: json.encode(
        {
          "shopInfo": prdRequest['shopInfo'],
          "reviewData": prdRequest['reviewData'],
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
