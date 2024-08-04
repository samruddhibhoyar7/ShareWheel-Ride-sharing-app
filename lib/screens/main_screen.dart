import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sharewheel/Assistants/assistant_methods.dart';
import 'package:sharewheel/global/global.dart';
import 'package:sharewheel/infoHandler/app_info.dart';
import 'package:sharewheel/screens/precise_pickup_location.dart';
import 'package:sharewheel/screens/rate_driver_screen.dart';
import 'package:sharewheel/screens/search_places_screen.dart';
import '../Assistants/geofire_assistant.dart';
import '../models/active_nearby_available_drivers.dart';
import '../splash_screen/splash_screen.dart';
import '../widgets/pay_fare_amount_dialog.dart';
import '../widgets/progress_dialog.dart';
import 'drawer_screen.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _makePhoneCall(String url) async {
  if(await canLaunch(url)) {
    await launch(url);
  }
  else{
    throw "Could not launch $url";
  }
}
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  LatLng? pickLocation;
  loc.Location location=loc.Location();
  String? _address;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  final GlobalKey<ScaffoldState> _scaffoldState= GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight =220;
  double waitingResponseFromDriverContainerHeight=0;
  double assignedDriverInfoContainerHeight=0;

  double suggestedRidesContainerHeight = 0;
  double searchingForDriverContainerHeight=0;

  Position? userCurrentPosition;
  var geoLocation=Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap=0;

  List<LatLng> pLineCoOrdinatesList=[];
  Set<Polyline> polylineSet={};

  Set<Marker> markerSet={};
  Set<Circle> circleSet={};

  String userName="";
  String userEmail="";

  bool openNavigationDrawer=true;
  bool activeNearbyDriverKeysLoaded=false;
  BitmapDescriptor? activeNearbyIcon;

  DatabaseReference? referenceRideRequest;

  String driverRideStatus = "Driver is coming";
  StreamSubscription<DatabaseEvent>? tripRidesRequestInfoStreamSubscription;
  List<ActiveNearByAvailableDrivers> onlineNearByAvailableDriversList = [];
  String userRideRequestStatus = "";
  bool requestPositionInfo = true;

locateUserPosition() async{
  AssistantMethods.readCurrentOnlineUserInfo();
  Position cPosition=await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  userCurrentPosition=cPosition;
  LatLng latLngPosition=LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
  CameraPosition cameraPosition=CameraPosition(target: latLngPosition,zoom:15);
  newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  String humanReadableAddress= await AssistantMethods.searchAddressForGeographicCoOrdinates(userCurrentPosition!, context);

  userName=userModelCurrentInfo!.name!;
  userEmail=userModelCurrentInfo!.email!;
  print("project");

  intializeGeoFireListener();
   AssistantMethods.readTripsKeysForOnlineUser(context);

  }
  intializeGeoFireListener(){
    Geofire.initialize("activeDrivers");
    Geofire.queryAtLocation(userCurrentPosition!.latitude,userCurrentPosition!.longitude,10)!.listen((map){
      print(map);
      if(map!=null){
        var callBack=map["callBack"];
        print(map["latitude"]);
        switch(callBack){
          case Geofire.onKeyEntered:
            GeoFireAssistant.activeNearByAvailableDriversList.clear();
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers=ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude=map["latitude"];
            activeNearByAvailableDrivers.locationLongitude=map["longitude"];
            activeNearByAvailableDrivers.driverId=map["key"];
            print('driverId: $activeNearByAvailableDrivers');
            GeoFireAssistant.activeNearByAvailableDriversList.add(activeNearByAvailableDrivers);
            if(activeNearbyDriverKeysLoaded==true){
              displayActiveDriversOnUsersMap();
            }
            break;

        // whenever any driver become inactive
          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineDriverFromList(map["key"]);
            displayActiveDriversOnUsersMap();
            break;

        //whenever driver moves updates location
          case Geofire.onKeyMoved:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers=ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude=map["latitude"];
            activeNearByAvailableDrivers.locationLongitude=map["longitude"];
            activeNearByAvailableDrivers.driverId=map["key"];
            GeoFireAssistant.updateActiveNearByAvailableDriverLocation(activeNearByAvailableDrivers);
            displayActiveDriversOnUsersMap();
            break;

        //display those online active drivers on user's map
          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded=true;
            displayActiveDriversOnUsersMap();
            break;
        }
      }

      setState(() {

      });
    });
  }

  displayActiveDriversOnUsersMap(){
    setState(() {
      markerSet.clear();
      circleSet.clear();

      Set<Marker> driversMarkerSet = <Marker>{};

      for(ActiveNearByAvailableDrivers eachDriver in GeoFireAssistant.activeNearByAvailableDriversList){
        LatLng eachDriverActivePosition =LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        Marker marker=Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );
        driversMarkerSet.add(marker);
      }
      setState(() {
        markerSet=driversMarkerSet;
      });
    });
  }

  createActiveNearByDriverIconMarker(){
    if(activeNearbyIcon==null){
      ImageConfiguration imageConfiguration= createLocalImageConfiguration(context,size: const Size(2,2));
      print("activeuser $activeNearbyDriverKeysLoaded");

      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.jpg").then((value) {
        activeNearbyIcon=value;
      });
      // BitmapDescriptor.fromAssetImage(imageConfiguration, "images/Bike_topview.jpeg").then((value) {
      //   activeNearbyIcon = value;
      // });
    }
  }

  Future<void> drawPolyLineFromOriginToDestination(bool darkTheme) async{
    var originPosition= Provider.of<AppInfo>(context,listen: false).userPickUpLocation;
    var destinationPosition= Provider.of<AppInfo>(context,listen: false).userDropOffLocation;
    print("userpickup: $originPosition, userdist: $destinationPosition");

    var originLatLng=LatLng(originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng=LatLng(destinationPosition!.locationLatitude!, destinationPosition.locationLongitude!);
    showDialog(
      context: context,
      builder: (BuildContext context)=> ProgressDialog(message: "Please wait...",),
    );
   var directionDetailInfo= await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);
   setState(() {
       tripDirectionDetailsInfo=directionDetailInfo;
    });

    Navigator.pop(context);
    PolylinePoints pPoints=PolylinePoints();
    List<PointLatLng> decodePolyLinePointsResultList=pPoints.decodePolyline(directionDetailInfo.e_points!);
    pLineCoOrdinatesList.clear();

    if(decodePolyLinePointsResultList.isNotEmpty){
      for (var pointLatLng in decodePolyLinePointsResultList) {
        pLineCoOrdinatesList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }
    polylineSet.clear();
    setState(() {
      Polyline polyline=Polyline(
        color:darkTheme? Colors.amberAccent:Colors.blue,
        polylineId:   PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );
      polylineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(originLatLng.latitude>destinationLatLng.latitude && originLatLng.longitude>destinationLatLng.longitude){
      boundsLatLng=LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude>destinationLatLng.longitude){
      boundsLatLng=LatLngBounds(
          southwest: LatLng(originLatLng.latitude,destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude)
      );
    }
    else if(originLatLng.latitude>destinationLatLng.latitude){
      boundsLatLng=LatLngBounds(
          southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
          northeast: LatLng(originLatLng.latitude,destinationLatLng.longitude)
      );
    }
    else{
      boundsLatLng=LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }
    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker=Marker(
      markerId:   const MarkerId("originID"),
      infoWindow: InfoWindow(title: originPosition.locationName,snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMarker=Marker(
      markerId:   const MarkerId("destinationID"),
      infoWindow: InfoWindow(title: destinationPosition.locationName,snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      markerSet.add(originMarker);
      markerSet.add(destinationMarker);
    });

    Circle originCircle=Circle(
      circleId:    CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle=Circle(
      circleId:    CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      circleSet.add(originCircle);
      circleSet.add(destinationCircle);
    });
  }
  void showSearchingForDriversContainer() {
    setState(() {
       searchingForDriverContainerHeight = 200;
    });
  }
  void showSuggestedRidesContainer() {
    setState(() {
      suggestedRidesContainerHeight = 400;
      bottomPaddingOfMap = 400;

    });
  }

  // getAddressFromLatLng() async{
    //   try{
    //     GeoData data= await Geocoder2.getDataFromCoordinates
    //       (latitude: pickLocation!.latitude,
    //         longitude: pickLocation!.longitude,
    //         googleMapApiKey: mapkey);
    //
    //     setState(() {
    //       Directions userPickUpAddress = Directions();
    //       userPickUpAddress.locationLatitude=pickLocation!.latitude;
    //       userPickUpAddress.locationLongitude=pickLocation!.longitude;
    //       userPickUpAddress.locationName=data.address;
    //       Provider.of<AppInfo>(context,listen:false).updatePickUpLocationAddress(userPickUpAddress);
    //       // _address=data.address;
    //     });
    //   } catch(e){
    //     print(e);
    //   }
    // }
  checkIfLocationPermissionAllowed() async{
    _locationPermission= await Geolocator.requestPermission();
    if(_locationPermission==LocationPermission.denied){
      _locationPermission= await Geolocator.requestPermission();
    }
  }
  saveRideRequestInformation(String selectedVehicleType) {
    referenceRideRequest =
        FirebaseDatabase.instance.ref().child("All Ride Requests").push();

    var originLocation = Provider
        .of<AppInfo>(context, listen: false)
        .userPickUpLocation;
    var destinationLocation = Provider
        .of<AppInfo>(context, listen: false)
        .userDropOffLocation;

    Map originLocationMap = {
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };

    Map destinationLocationMap = {
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };

    Map userInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInformationMap);


    tripRidesRequestInfoStreamSubscription =
        referenceRideRequest!.onValue.listen((eventSnap) async {
          if (eventSnap.snapshot.value == null) {
            return;
          }

          if ((eventSnap.snapshot.value as Map)["car_details"] != null) {
            setState(() {
              driverCarDetails =
                  (eventSnap.snapshot.value as Map)["car_details"].toString();
            });
          }
          if((eventSnap.snapshot.value as Map)["driverPhone"] != null){
            setState(() {
              driverPhone = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
            });
          }

          if((eventSnap.snapshot.value as Map)["driverName"] != null){
            setState(() {
              driverName = (eventSnap.snapshot.value as Map)["driverName"].toString();
            });
          }
          // if ((eventSnap.snapshot.value as Map)["driverPhone"] != null) {
          //   setState(() {
          //     driverCarDetails =
          //         (eventSnap.snapshot.value as Map)["driverPhone"].toString();
          //   });
          // }
          //
          // if ((eventSnap.snapshot.value as Map)["driverName"] != null) {
          //   setState(() {
          //     driverCarDetails =
          //         (eventSnap.snapshot.value as Map)["driverName"].toString();
          //   });
          // }
          if((eventSnap.snapshot.value as Map)["ratings"] != null){
            setState(() {
              driverRatings = (eventSnap.snapshot.value as Map)["ratings"].toString();
            });
          }


          if ((eventSnap.snapshot.value as Map)["status"] != null) {
            setState(() {
              userRideRequestStatus =
                  (eventSnap.snapshot.value as Map)["status"].toString();
            });
          }

          if ((eventSnap.snapshot.value as Map)["driverLocation"] != null) {
            double driverCurrentPositionLat = double.parse(
                (eventSnap.snapshot.value as Map)["driverLocation"]["latitude"]
                    .toString());
            double driverCurrentPositionLng = double.parse(
                (eventSnap.snapshot.value as Map)["driverLocation"]["longitude"]
                    .toString());

            LatLng driverCurrentPositionLatLng = LatLng(
                driverCurrentPositionLat, driverCurrentPositionLng);

            if (userRideRequestStatus == "accepted") {
              updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
            }

            if (userRideRequestStatus == "arrived") {
              setState(() {
                driverRideStatus = "Driver has arrived";
              });
            }

            if (userRideRequestStatus == "ontrip") {
              updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
            }

            if (userRideRequestStatus == "ended") {
              if ((eventSnap.snapshot.value as Map)["fareAmount"] != null) {
                double fareAmount = double.parse(
                    (eventSnap.snapshot.value as Map)["fareAmount"].toString());

                var response = await showDialog(
                    context: context,
                    builder: (BuildContext context) =>
                        PayFareAmountDialog(
                          totalFareAmount: totalFareAmount,
                        )
                );

                if (response == "Cash Paid") {
                  if ((eventSnap.snapshot.value as Map)["driverId"] != null) {
                    String assignedDriverId = (eventSnap.snapshot
                        .value as Map)["driverId"].toString();
                    // Here you need to import the file
                    Navigator.push(context, MaterialPageRoute(builder: (c) => RateDriverScreen(
                      assignedDriverId : assignedDriverId,
                    )));
                    referenceRideRequest!.onDisconnect();
                    tripRidesRequestInfoStreamSubscription!.cancel();
                  }
                }
              }
            }
          }
        });

    onlineNearByAvailableDriversList =
        GeoFireAssistant.activeNearByAvailableDriversList;
    searchNearestOnlineDrivers(selectedVehicleType);
  }
    searchNearestOnlineDrivers(String selectedVehicleType) async {
      if(onlineNearByAvailableDriversList.isEmpty){

        referenceRideRequest!.remove();

        setState(() {
          polylineSet.clear();
          markerSet.clear();
          circleSet.clear();
          pLineCoOrdinatesList.clear();

        });

        Fluttertoast.showToast(msg: "No online nearest Driver Available");
        Fluttertoast.showToast(msg: "Search Again. \n Restarting App");

        Future.delayed( const Duration(milliseconds: 4000), () {
          referenceRideRequest!.remove();
          Navigator.push(context, MaterialPageRoute(builder: (c) =>  const SplashScreen()));
        });

        return;

      }

      await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

      print("Drivers List: $driversList");

      for(int i=0; i < driversList.length; i++){
        if(driversList[i]["car_details"]["type"] == selectedVehicleType){
          AssistantMethods.sendNotificationToDriverNow(driversList[i]["token"], referenceRideRequest!.key!, context);

        }
      }

      Fluttertoast.showToast(msg: "Notification sent Successfully");

      showSearchingForDriversContainer();

      FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).child("driverId").onValue.listen((eventRideRequestSnapshot) {
        print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
        if(eventRideRequestSnapshot.snapshot.value != null){
          if(eventRideRequestSnapshot.snapshot.value != "waiting"){
            showUIForAssignedDriverInfo();
          }
        }
      });
    }


    updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng) async {
      if(requestPositionInfo == true){
        requestPositionInfo = false;
        LatLng userPickUpPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

        var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            driverCurrentPositionLatLng, userPickUpPosition
        );

        setState(() {
          driverRideStatus = "Driver is coming:${directionDetailsInfo.distance_text} ";
        });

        requestPositionInfo = true;

      }
    }

    updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
      if(requestPositionInfo == true){
        requestPositionInfo = false;

        var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

        LatLng userDestinationPosition = LatLng(
            dropOffLocation!.locationLatitude!,
            dropOffLocation.locationLongitude!
        );

        var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            driverCurrentPositionLatLng,
            userDestinationPosition
        );

        setState(() {

          driverRideStatus = "Going Towards Destination: ${directionDetailsInfo.duration_text} mins";
        });

        requestPositionInfo = true;

      }
    }

    showUIForAssignedDriverInfo() {
      setState(() {
        waitingResponseFromDriverContainerHeight = 0;
        searchLocationContainerHeight = 0;
        assignedDriverInfoContainerHeight = 200;
        suggestedRidesContainerHeight = 0;
        bottomPaddingOfMap = 200;
      });
    }

    retrieveOnlineDriversInformation(List onlineNearestDriversList) async {

      driversList.clear();
      DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");

      for(int i = 0; i < onlineNearestDriversList.length; i++){
        await ref.child(onlineNearestDriversList[i].driverId.toString()).once().then((dataSnapshot) {
          var driverKeyInfo = dataSnapshot.snapshot.value;

          driversList.add(driverKeyInfo);
          print("driver key information = $driversList");
        });
      }
    }

    @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkIfLocationPermissionAllowed();
  }


  @override
  Widget build(BuildContext context) {
  bool darkTheme= MediaQuery.of(context).platformBrightness==Brightness.dark;
  createActiveNearByDriverIconMarker();

    return  GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
          key: _scaffoldState,
          drawer:  DrawerScreen(),
          body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              initialCameraPosition: _kGooglePlex,
              polylines: polylineSet,
              markers: markerSet,
              circles: circleSet,
              onMapCreated: (GoogleMapController controller){
                _controllerGoogleMap.complete(controller);
                newGoogleMapController=controller;

                setState(() {
                  bottomPaddingOfMap=200;
                });

                locateUserPosition();
              },
              // onCameraMove: (CameraPosition? position){
              //   if(pickLocation!= position!.target){
              //     setState(() {
              //       pickLocation =position.target;
              //     });
              //   }
              // },
              // onCameraIdle: (){
              // getAddressFromLatLng();
              // },
            ),
            // Align(
            //   alignment: Alignment.center,
            //   child: Padding(
            //     padding: const EdgeInsets.only(bottom: 35.0),
            //     child: Image.asset("images/pick.jpg",height: 45,width: 45,),
            //   ),
            // ),
      //custom hamburger button for drawer
              Positioned(
                top: 50,
                left: 20,
                child: Container (
                  child: GestureDetector(
                    onTap: () {
                      _scaffoldState.currentState!.openDrawer();
                    },
                      child: CircleAvatar(
                    backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.white,
                        child: Icon(
                          Icons.menu,
                          color: darkTheme ? Colors.black : Colors.lightBlue,
                        ),
                  ),
                ),
              ),
            ),


             Positioned(
                  bottom: 0,
                  left:0,
                  right: 0,
                  child:Padding(
                    padding:     EdgeInsets.fromLTRB(10, 50, 10, 10),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding:    EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:  Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                        padding:   EdgeInsets.all(5),
                                    child: Row(
                                      children: [
                                           Icon(Icons.location_on_outlined,color: Colors.blue,),
                                           SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                               Text("From",
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(  Provider.of<AppInfo>(context).userPickUpLocation !=null ?
                                                  "${(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0,24)}...":
                                                  "Not getting Address",
                                            style:    TextStyle(
                                              color: Colors.grey,fontSize: 14,
                                            ),
                                            ),

                                          ],
                                        )
                                      ],
                                    ),


                              ),
                                   SizedBox(height: 5,),
                                   Divider(
                                  height: 1,
                                  thickness: 2,
                                  color: Colors.blue,
                              ),
                                 SizedBox(height: 5,),

                                  Padding(padding:    EdgeInsets.all(5),
                                    child: GestureDetector(
                                      onTap: () async {
                                     var responseFromSearchScreen=await Navigator.push(context, MaterialPageRoute(builder:(c)=> SearchPlacesScreen()));

                                   if(responseFromSearchScreen=='obtainedDropOff'){
                                     setState(() {
                                       openNavigationDrawer=false;
                                     });
                               }
                               await drawPolyLineFromOriginToDestination(darkTheme);
                                },
                                        child: Row(
                                          children: [
                                               Icon(Icons.location_on_outlined,color: Colors.blue,),
                                               SizedBox(width: 10,),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                   Text("To",
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                        ),
                                                Text(Provider.of<AppInfo>(context).userDropOffLocation !=null ?
                                                Provider.of<AppInfo>(context).userDropOffLocation!.locationName!
                                                :"Where to?",
                                                  style:    TextStyle(
                                                    color: Colors.grey,fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                    )
                                  ],
                                ),
                              )
                              )
                            ],
                          ) ,
                        ),
                             SizedBox(height: 5,),

                            Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                        child:ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (c) =>   PrecisePickUpScreen()));
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                              textStyle:   TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              )
                                          ),
                                          child: Text(
                                            "Change Pick Up Address",
                                            style: TextStyle(
                                              color: darkTheme ? Colors.black : Colors.white,
                                            ),
                                          ),
                                        ),
                                    ),

                                    SizedBox(width: 10,),
                                Expanded(

                                    child: ElevatedButton(
                                      onPressed: () {
                                        if(Provider.of<AppInfo>(context,listen: false).userDropOffLocation != null){
                                          showSuggestedRidesContainer();
                                        }
                                        if(Provider.of<AppInfo>(context,listen: false).userDropOffLocation != null){
                                          showSuggestedRidesContainer();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                          textStyle:   TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          )
                                      ),
                                      child: Text(
                                        "Show Fare",
                                        style: TextStyle(
                                          color: darkTheme ? Colors.black : Colors.white,
                                        ),
                                      ),
                                    ),
                                )

                          ],
                    ) ,
                    ],
                  ),
                    )
                ],
              ),
            ),
             ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: suggestedRidesContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius :   BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding:   EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children : [
                      Row(
                        children: [
                          Container(
                            padding:   EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                              borderRadius : BorderRadius.circular(2),
                            ),
                            child:   Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),

                            SizedBox(width: 15,),

                          Text(
                            Provider.of<AppInfo>(context).userPickUpLocation !=null ?
                            "${(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0,24)}...":
                            "Not getting Address",
                            style:   TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                        SizedBox(height: 20,),


                      Row(
                        children: [
                          Container(
                            padding:   EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius : BorderRadius.circular(2),
                            ),
                            child:   Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),

                            SizedBox(width: 15,),

                          Text(
                            Provider.of<AppInfo>(context).userDropOffLocation !=null ?
                            Provider.of<AppInfo>(context).userDropOffLocation!.locationName!
                                :"Where to?",
                            style:   TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                        SizedBox(height: 20,),

                        Text("SUGGESTED RIDES",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                       const SizedBox(height: 20,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {

                                selectedVehicleType = "Car";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Car" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: Padding(
                                padding:   EdgeInsets.all(10.0),
                                child: Column(
                                  children: [
                                    Image.asset("images/Car.png", scale:4,),

                                      SizedBox(height: 8,),

                                    Text(
                                      "Car",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "Car" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white : Colors.black),
                                      ),
                                    ),

                                      SizedBox(height: 2,),

                                    Text(
                                      tripDirectionDetailsInfo != null ? "Rs  ${((AssistantMethods.calculateFareAmountfromOriginToDestination(tripDirectionDetailsInfo!) * 2)*43).toStringAsFixed(1)}"
                                          : "null",
                                      style:   TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "CNG";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "CNG" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding:   EdgeInsets.all(10.0),
                                child: Column(
                                  children: [
                                    Image.asset("images/CNG.png", scale:4,),

                                      SizedBox(height: 8,),

                                    Text(
                                      "CNG",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "CNG" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white : Colors.black),
                                      ),
                                    ),

                                     SizedBox(height: 2,),

                                    Text(
                                      tripDirectionDetailsInfo != null ? "Rs  ${((AssistantMethods.calculateFareAmountfromOriginToDestination(tripDirectionDetailsInfo!) * 1.5)*50).toStringAsFixed(1)}"
                                          : "null",
                                      style:   TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),


                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "Bike";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Bike" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding:  EdgeInsets.all(10.0),
                                child: Column(
                                  children: [
                                    Image.asset("images/Bike.png", scale:4,),

                                      SizedBox(height: 8,),

                                    Text(
                                      "Bike",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "Bike" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white : Colors.black),
                                      ),
                                    ),

                                      SizedBox(height: 2,),

                                    Text(
                                      tripDirectionDetailsInfo != null ? "Rs  ${((AssistantMethods.calculateFareAmountfromOriginToDestination(tripDirectionDetailsInfo!) * 0.8)*60).toStringAsFixed(1)}"
                                          : "null",
                                      style:   TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                        SizedBox(height: 30,),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if(selectedVehicleType != ""){
                              saveRideRequestInformation(selectedVehicleType);
                            }
                            else{
                              Fluttertoast.showToast(msg: "Please select a vehicle from \n suggested rides.");
                            }

                          },
                          child: Container(
                            padding:   EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "Resquest a Ride",
                                style: TextStyle(
                                  color: darkTheme ? Colors.black : Colors.white,
                                  fontWeight : FontWeight.bold,
                                  fontSize : 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),


                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: searchingForDriverContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme? Colors.black : Colors.white,
                  borderRadius:  BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                ),
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),

                       SizedBox(height: 10,),

                       Center(
                        child: Text(
                          "Searching for a driver...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                       SizedBox(height: 20,),

                      GestureDetector(
                        onTap: () {
                          referenceRideRequest!.remove();
                          setState(() {
                            searchingForDriverContainerHeight = 0;
                            suggestedRidesContainerHeight = 0;
                          });
                        },

                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: darkTheme ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1, color: Colors.grey),
                          ),
                          child:  Icon(Icons.close, size: 25,),
                        ),
                      ),

                       SizedBox(height: 15,),

                       SizedBox(
                        width: double.infinity,
                        child: Text(
                          "Cancel",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),

                        ),
                      )


                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: assignedDriverInfoContainerHeight,
                decoration: BoxDecoration(
                    color: darkTheme ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(driverRideStatus, style: TextStyle(fontWeight: FontWeight.bold),),
                      SizedBox(height: 2,),
                      Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                      SizedBox(height: 2,),
                      Row(
                        mainAxisAlignment : MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: darkTheme ? Colors.amber.shade400 : Colors.lightBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.person, color: darkTheme ? Colors.black : Colors.white,),

                              ),

                              SizedBox(width: 5,),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(driverName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),),

                                  Row(children: [
                                    Icon(Icons.star,color: Colors.orange,),

                                    SizedBox(width: 5,),
                                    Text(driverRatings,
                                      style: TextStyle(
                                          color: Colors.grey
                                      ),
                                    ),
                                  ],),
                                ],
                              )

                            ],
                          ),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Image.asset("images/Car.png", scale: 8,),

                              Text(driverCarDetails, style: TextStyle(fontSize: 12),),
                            ],
                          )
                        ],
                      ),

                      SizedBox(height: 2,),
                      Divider(thickness: 1,
                        color : darkTheme ? Colors.grey : Colors.grey[300],),
                      ElevatedButton.icon(
                        onPressed: () {
                          _makePhoneCall("tel: ${driverPhone}");
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue),
                        icon: Icon(Icons.phone),
                        label: Text("Call Driver"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ),
    );
  }
}

// Positioned(
//   top:40,
//   right: 20,
//   left:20,
//   child:Container(
//     decoration: BoxDecoration(
//       border: Border.all(color: Colors.black),
//       color: Colors.white,
//     ),
//     padding: EdgeInsets.all(20),
//     child: Text(
//       Provider.of<AppInfo>(context).userPickUpLocation !=null ?
//       (Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0,24) +"...":
//       "Not getting Address",
//       overflow: TextOverflow.visible, softWrap: true,
//     ),
//   ) ,
// )