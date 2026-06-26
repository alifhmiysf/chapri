import 'dart:math';


class ChapriIdGenerator {


  static String generate(String username){


    final random =
    Random();


    final number =
    random.nextInt(90000) + 10000;



    return "${username.toUpperCase()}#$number";


  }


}