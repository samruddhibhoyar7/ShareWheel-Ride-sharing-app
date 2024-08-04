import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sharewheel/global/global.dart';
import 'package:sharewheel/models/directions.dart';
import 'package:sharewheel/models/user_model.dart';
import 'package:http/http.dart' as http;
import '../infoHandler/app_info.dart';
import '../models/direction_details_info.dart';
import '../models/trips_history_model.dart';


class AssistantMethods {
   static void readCurrentOnlineUserInfo() async {
    currentUser = firebaseAuth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("sharewheel")
        .child(currentUser!.uid);

    userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);

      }
    });
  }

  static Future<String> searchAddressForGeographicCoOrdinates(Position position, context) async {
    var latitude = position.latitude;
    var longitude = position.longitude;
    var uri = Uri.https(
        'api.mapbox.com', 'geocoding/v5/mapbox.places/$longitude,$latitude.json', {
      'access_token': 'pk.eyJ1Ijoic2FtcnVkZGhpYmhveWFyIiwiYSI6ImNscHdqNXFlZjBnaGwybmx3ZzA5dmdwY3oifQ.qGdl73SldqNParw_gjQdsA',
      'country': 'IN',
      'worldview': 'in'
    });

    final requestResponse = await http.get(uri);
    String humanReadableAddress = "";
    //   String apiUrl= "https://google-maps-geocoding.p.rapidapi.com/geocode/json?latlng=${position.latitude},${position.longitude}"
    //
    //    var requestResponse= await RequestAssistant.receiveRequest(apiUrl);
    //

    if(requestResponse!= "Error Occured. Failed. No Response."){
      var decoded = json.decode(requestResponse.body);
      humanReadableAddress = decoded["features"][0]["place_name"];

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude= latitude;
      userPickUpAddress.locationLongitude= longitude;
      userPickUpAddress.locationName=humanReadableAddress;

      var pickLat = userPickUpAddress.locationLatitude;
      var pickLong = userPickUpAddress.locationLongitude;
      var id = userPickUpAddress.locationId;

      Provider.of<AppInfo>(context,listen:false).updatePickUpLocationAddress(userPickUpAddress);
    }

    return humanReadableAddress;

}

  static Future<DirectionDetailsInfo> obtainOriginToDestinationDirectionDetails(LatLng originPosition, LatLng destinationPosition) async{
    var lat = originPosition.latitude;
    var long = originPosition.longitude;
    var destLat = destinationPosition.latitude;
    var destLong = destinationPosition.longitude;


    print("LAT $originPosition");
    var urlOriginToDestinationDirectionDetails=Uri.https(
        'api.mapbox.com', 'directions/v5/mapbox/driving-traffic/$long,$lat;$destLong,$destLat', {
      'access_token': 'pk.eyJ1Ijoic2FtcnVkZGhpYmhveWFyIiwiYSI6ImNscHdqNXFlZjBnaGwybmx3ZzA5dmdwY3oifQ.qGdl73SldqNParw_gjQdsA',
      'waypoints_per_route':'true'
    });
    print("url5: $urlOriginToDestinationDirectionDetails");
    final responseDirectionApi=await http.get(urlOriginToDestinationDirectionDetails);
     var decoded = json.decode(responseDirectionApi.body);

    if (decoded['type'] == "Error Occured. Failed. No Response.") {
      // Handle error
      print("Error Occurred: ${decoded['routes']}");
    }
    var DestinationDirection = decoded["routes"][0];
    print("Destination: $DestinationDirection");
    //var subtype = DestinationDirection["legs"][0]["notifications"];
   // print("SUB $subtype");
     DirectionDetailsInfo directionDetailsInfo= DirectionDetailsInfo();
     directionDetailsInfo.e_points=DestinationDirection["waypoints"][0]["location"].toString();

     directionDetailsInfo.distance_value=DestinationDirection["distance"].toInt();
    var distance= directionDetailsInfo.distance_value;
    print("distance : $distance");
    if(distance!=null) {
     var dist_text= distance ~/ 1000;
     print("duration_value: $dist_text");
     directionDetailsInfo.distance_text= dist_text.toString();
    }
    directionDetailsInfo.duration_value=DestinationDirection["duration"].toInt();
    var duration= directionDetailsInfo.duration_value;
    if(duration!=null){
      var dura_text =(duration/60).toDouble();
      directionDetailsInfo.duration_text=dura_text.toString();
      print("duration_value: $dura_text");
    }
   // print("e_points: $directionDetailsInfo.e_points, distance_Value: $directionDetailsInfo.distance_value, duration: $directionDetailsInfo");
     return directionDetailsInfo;

  }
   static double calculateFareAmountfromOriginToDestination(DirectionDetailsInfo directionDetailsInfo){
     double timeTraveledFareAmountPerMinute = (directionDetailsInfo.duration_value! /60) * 0.1;
     double distanceTraveledFareAmountPerKilometer = (directionDetailsInfo.duration_value! /1000) * 0.1;

     //USD
     double totalFareAmount = timeTraveledFareAmountPerMinute  + distanceTraveledFareAmountPerKilometer;

     return double.parse(totalFareAmount.toStringAsFixed(1));
   }

   static double calculateFareAmountFromOriginToDestination(DirectionDetailsInfo directionDetailsInfo){
    double timeTraveledFareAmountPerMinute = (directionDetailsInfo.duration_value! /60) * 0.05;
    double distanceTraveledFareAmountPerKilometer = (directionDetailsInfo.duration_value! /1000) * 0.05;

    //USD
    totalFareAmount = timeTraveledFareAmountPerMinute  + distanceTraveledFareAmountPerKilometer;
    double localCurrencyTotalFare=0;
    // return double.parse(totalFareAmount.toStringAsFixed(1));

    if (selectedVehicleType == "Bike") {
      localCurrencyTotalFare= totalFareAmount * 60;
      totalFareAmount = ((localCurrencyTotalFare.truncate()) * 1.6);
      return totalFareAmount;
    } else if (selectedVehicleType == "CNG") {
      localCurrencyTotalFare = totalFareAmount * 50;
      totalFareAmount = ((localCurrencyTotalFare.truncate()) * 3);
      return totalFareAmount;
    } else if ( selectedVehicleType == "Car") {
      localCurrencyTotalFare = totalFareAmount * 43;
      totalFareAmount = ((localCurrencyTotalFare.truncate()) * 4);
      print("TotalAmount: $totalFareAmount");
      return totalFareAmount;
    } else  {
      localCurrencyTotalFare = totalFareAmount * 107;
      print("Fare: ${localCurrencyTotalFare.truncate().toDouble()}");
      return localCurrencyTotalFare.truncate().toDouble();
    }

  }
   static sendNotificationToDriverNow(String deviceRegistrationToken, String userRideRequestId, context) async {
     String destinationAddress = userDropOffAddress;

     Map<String, String> headerNotification = {
       'Content-Type': 'application/json',
       'Authorization': cloudMessagingServerToken,
     };

     Map bodyNotification = {
       "body":"Destination Address: \n$destinationAddress.",
       "title":"New Trip Request"
     };

     Map dataMap = {
       "click_action": "FLUTTER_NOTIFICATION_CLICK",
       "id": "1",
       "status": "done",
       "rideRequestId": userRideRequestId
     };

     Map officialNotificationFormat = {
       "notification": bodyNotification,
       "data": dataMap,
       "priority":"high",
       "to":deviceRegistrationToken,
     };

     var responseNotification = await http.post(
       Uri.parse("https://fcm.googleapis.com/fcm/send"),
       headers: headerNotification,
       body: jsonEncode(officialNotificationFormat),

     );
     var decoded=json.decode(responseNotification.body);
      print( "responseNotification: $decoded");
   }
   static void readTripsKeysForOnlineUser(context){

     FirebaseDatabase.instance.ref().child("All Ride Requests").orderByChild("userName").equalTo(userModelCurrentInfo!.name).once().then((snap){
       if(snap.snapshot.value != null){
         Map keysTripsId = snap.snapshot.value as Map;

         int overAllTripsCounter = keysTripsId.length;
         Provider.of<AppInfo>(context, listen: false).updateOverAllTripsCounter(overAllTripsCounter);

         List<String> tripsKeysList = [];
         keysTripsId.forEach((key, value) {
           tripsKeysList.add(key);
         });
         Provider.of<AppInfo>(context, listen: false).updateOverAllTripsKeys(tripsKeysList);

         readTripsHistoryInformation(context);
       }
     });
   }

   static void readTripsHistoryInformation(context){

     var tripsAllKeys = Provider.of<AppInfo>(context, listen: false).historyTripsKeysList;

     for(String eachKey in tripsAllKeys){
       FirebaseDatabase.instance.ref()
           .child("All Ride Requests")
           .child(eachKey)
           .once()
           .then((snap)
       {
         var eachTripHistory = TripsHistoryModel.fromSnapShot(snap.snapshot);

         if((snap.snapshot.value as Map)["status"] == "ended"){
           print("eachTripHistory: $eachTripHistory");
           Provider.of<AppInfo>(context, listen: false).updateOverAllTripHistoryInformation(eachTripHistory);
         }
       });
     }
   }
}

