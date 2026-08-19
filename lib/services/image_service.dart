import 'dart:convert';
import 'package:http/http.dart' as http;


class ImageService {


  static Future<String> getHeritageImage(
      String name
      ) async {


    final url = Uri.parse(
        "https://commons.wikimedia.org/w/api.php"
            "?action=query"
            "&generator=search"
            "&gsrsearch=${Uri.encodeComponent(name)}"
            "&gsrnamespace=6"
            "&gsrlimit=1"
            "&prop=imageinfo"
            "&iiprop=url"
            "&format=json"
    );


    final response =
    await http.get(url);



    if(response.statusCode != 200){

      return "";

    }



    final data =
    json.decode(response.body);



    final pages =
    data["query"]?["pages"];



    if(pages == null){

      return "";

    }



    final firstPage =
        pages.values.first;



    final imageInfo =
    firstPage["imageinfo"];



    if(imageInfo == null){

      return "";

    }



    return imageInfo[0]["url"] ?? "";


  }


}