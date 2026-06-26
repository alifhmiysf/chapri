import 'package:flutter/material.dart';

import '../auth/login_page.dart';
import '../auth/register_page.dart';


class WelcomePage extends StatelessWidget {

  const WelcomePage({super.key});


  @override
  Widget build(BuildContext context) {


    return Scaffold(

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.all(24),

          child: Column(

            mainAxisAlignment:
            MainAxisAlignment.center,


            children: [


              const Spacer(),



              Icon(

                Icons.favorite,

                size:90,

                color:Colors.blue,

              ),



              const SizedBox(height:25),



              const Text(

                "CHAPRI",

                style:TextStyle(

                  fontSize:36,

                  fontWeight:FontWeight.bold,

                  letterSpacing:4,

                ),

              ),



              const SizedBox(height:15),



              Text(

                "Private & Secure Messenger",

                style:TextStyle(

                  fontSize:16,

                  color:Colors.grey[600],

                ),

              ),



              const Spacer(),



              SizedBox(

                width:double.infinity,

                height:55,


                child:ElevatedButton(

                  onPressed:(){


                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder:(_)=>
                        const LoginPage(),

                      ),

                    );


                  },


                  style:ElevatedButton.styleFrom(

                    shape:RoundedRectangleBorder(

                      borderRadius:
                      BorderRadius.circular(15),

                    ),

                  ),


                  child:const Text(

                    "Login",

                    style:TextStyle(

                      fontSize:18,

                    ),

                  ),

                ),

              ),



              const SizedBox(height:15),



              SizedBox(

                width:double.infinity,

                height:55,


                child:OutlinedButton(


                  onPressed:(){


                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder:(_)=>
                        const RegisterPage(),

                      ),

                    );


                  },


                  style:OutlinedButton.styleFrom(

                    shape:RoundedRectangleBorder(

                      borderRadius:
                      BorderRadius.circular(15),

                    ),

                  ),


                  child:const Text(

                    "Create Account",

                    style:TextStyle(

                      fontSize:18,

                    ),

                  ),

                ),

              ),



              const SizedBox(height:30),


            ],


          ),

        ),

      ),

    );

  }

}