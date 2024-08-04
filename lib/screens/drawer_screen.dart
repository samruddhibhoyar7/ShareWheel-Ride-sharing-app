import 'package:flutter/material.dart';
import 'package:sharewheel/global/global.dart';
import 'package:sharewheel/screens/profile_screen.dart';
import 'package:sharewheel/screens/trips_history_screen.dart';
import 'package:sharewheel/splash_screen/splash_screen.dart';



class DrawerScreen extends StatelessWidget {
  const DrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Drawer(
        child: Padding(
          padding:  const EdgeInsets.fromLTRB(30, 50, 0, 20),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:  const EdgeInsets.all(30),
                    decoration:  const BoxDecoration(
                      color: Colors.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child:  const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),

                   const SizedBox(height: 20,),

                  Text(
                    userModelCurrentInfo!.name!,
                    style:  const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                   const SizedBox(height: 10,),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) =>  const ProfileScreen()));
                    },
                    child:  const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  SizedBox(height: 30,),

                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (c)=> TripsHistoryScreen()));
                    },
                    child: Text("Your Trips", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                  ),
                    SizedBox(height: 15,),

                ],
              ),

              GestureDetector(
                onTap: () {
                  firebaseAuth.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c) =>  SplashScreen()));
                },
                child:   Text(
                  "Logout",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}