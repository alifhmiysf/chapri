class UserModel {


  final String uid;

  final String name;

  final String username;

  final String chapriId;

  final String email;

  final String photoUrl;

  final String status;



  UserModel({

    required this.uid,

    required this.name,

    required this.username,

    required this.chapriId,

    required this.email,

    this.photoUrl = "",

    this.status = "Hey, I'm using Chapri",

  });



  Map<String,dynamic> toMap(){


    return {


      "uid":uid,

      "name":name,

      "username":username,

      "chapriId":chapriId,

      "email":email,

      "photoUrl":photoUrl,

      "status":status,


    };


  }



  factory UserModel.fromMap(
      Map<String,dynamic> map
      ){


    return UserModel(

      uid:map["uid"],

      name:map["name"],

      username:map["username"],

      chapriId:map["chapriId"],

      email:map["email"],

      photoUrl:
      map["photoUrl"] ?? "",

      status:
      map["status"] ??
      "Hey, I'm using Chapri",

    );


  }


}