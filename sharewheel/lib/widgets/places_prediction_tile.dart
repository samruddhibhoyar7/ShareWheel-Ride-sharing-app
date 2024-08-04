import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sharewheel/models/predicted_places.dart';
import 'package:sharewheel/widgets/progress_dialog.dart';
import 'package:http/http.dart ' as http;

import '../global/global.dart';
import '../infoHandler/app_info.dart';
import '../models/directions.dart';


class PlacesPredictionTileDesign extends StatefulWidget {

  final PredictedPlaces? predictedPlaces;

  const PlacesPredictionTileDesign({super.key, this.predictedPlaces});

  @override
  State<PlacesPredictionTileDesign> createState() => _PlacesPredictionTileDesignState();
}

class _PlacesPredictionTileDesignState extends State<PlacesPredictionTileDesign> {

  getPlaceDirectionDetails(mainText, context) async{
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
          message: "Setting up Drop-off. Please wait.....",
        )
    );

    var urlPlaceDetails = Uri.https(
        'api.mapbox.com', 'geocoding/v5/mapbox.places/$mainText.json', {
      'access_token': 'pk.eyJ1Ijoic2FtcnVkZGhpYmhveWFyIiwiYSI6ImNscHdqNXFlZjBnaGwybmx3ZzA5dmdwY3oifQ.qGdl73SldqNParw_gjQdsA',
    });
    print("uri1: $urlPlaceDetails");

    final responsePlaceDetails = await http.get(urlPlaceDetails);
    Navigator.pop(context);

    if (responsePlaceDetails.statusCode != 200) {
      // Handle error, e.g., by throwing an exception or returning
      print("Error Occurred: ${responsePlaceDetails.reasonPhrase}");
      return;
    }

    var decoded = json.decode(responsePlaceDetails.body);

    if (decoded['type'] == "Error Occured. Failed. No Response.") {
      // Handle error
      print("Error Occurred: ${decoded['type']}");
      return;
    }

    var placeDetails = decoded["features"][0]; // Assuming you want the first feature

    Directions directions = Directions();
    directions.locationName = placeDetails["text"];
    directions.locationId = placeDetails["id"];
    directions.locationLatitude = placeDetails["geometry"]["coordinates"][1].toDouble();
    directions.locationLongitude = placeDetails["geometry"]["coordinates"][0].toDouble();


    Provider.of<AppInfo>(context, listen: false).updateDropOffLocationAddress(directions);
    setState(() {
      userDropOffAddress = directions.locationName!;
    });

    Navigator.pop(context, "obtainedDropOff");

  }

  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return ElevatedButton(
      onPressed: (){
        getPlaceDirectionDetails(widget.predictedPlaces!.main_text,context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: darkTheme ? Colors.black : Colors.white,
      ),
      child: Padding(
        padding:  const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              Icons.add_location,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),

             const SizedBox(width: 10,),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.predictedPlaces!.main_text!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                  ),

                  Text(
                    widget.predictedPlaces!.secondary_text!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}