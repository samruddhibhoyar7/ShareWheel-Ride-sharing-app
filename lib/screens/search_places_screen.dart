import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sharewheel/models/predicted_places.dart';
import 'package:http/http.dart' as http;
import 'package:sharewheel/widgets/places_prediction_tile.dart';


class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen>{
  List<PredictedPlaces> placesPredictedList=[];

  findPlaceAutoCompleteSearch(String inputText) async{

    if(inputText.length>1) {
      var urlAutoCompleteSearch = Uri.https(
          'api.mapbox.com', 'search/searchbox/v1/suggest', {
        'access_token': 'pk.eyJ1Ijoic2FtcnVkZGhpYmhveWFyIiwiYSI6ImNscHdqNXFlZjBnaGwybmx3ZzA5dmdwY3oifQ.qGdl73SldqNParw_gjQdsA',
        'session_token': 'db4db791-1439-4e18-a2d0-e40523149aa2',
        'q': inputText
      });
      final responseAutoCompleteSearch = await http.get(urlAutoCompleteSearch);

      // var responseAutoCompleteSearch =
      // await RequestAssistant.receiveRequest(urlAutoCompleteSearch);

      if (responseAutoCompleteSearch == "Error Occured. Failed. No Response.") {
        return;
      }

      var decoded = json.decode(responseAutoCompleteSearch.body);
      var placePredictions = decoded['suggestions'];

      print("seach url: $urlAutoCompleteSearch");
      List<dynamic> dynamicPredictedList = placePredictions.map((e) => PredictedPlaces.fromJson(e)).toList();
      List <PredictedPlaces> predictedList = dynamicPredictedList.cast<PredictedPlaces>();

      setState(() {
        placesPredictedList = predictedList;
      });
    }
    }


  @override
  Widget build(BuildContext context){
    bool darkTheme= MediaQuery.of(context).platformBrightness==Brightness.dark;
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: darkTheme?Colors.black:Colors.white,
        appBar: AppBar(
          backgroundColor: darkTheme?Colors.amber.shade400:Colors.blue,
          leading: GestureDetector(
            onTap: (){
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back,color: darkTheme?Colors.black:Colors.white,),
          ),
          title: Text(
            "Search & Set dropoff location",
            style: TextStyle(color: darkTheme? Colors.black:Colors.white),
          ),
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkTheme?Colors.amber.shade400:Colors.blue,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white54,
                    blurRadius: 8,
                    spreadRadius: 0.5,
                    offset: Offset(
                        0.7,0.7
                    ),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.adjust_sharp,color: darkTheme?Colors.black:Colors.white,),
                        const SizedBox(height: 18.0,),
                        Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                onChanged: (value){
                                  findPlaceAutoCompleteSearch(value);
                                },
                                decoration: InputDecoration(
                                    hintText: "Search location here...",
                                    fillColor: darkTheme? Colors.black:Colors.white,
                                    filled: true,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(
                                      left: 11,
                                      top: 8,
                                      bottom: 8,
                                    )
                                ),
                              ),
                            )
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
//display predicted places
          (placesPredictedList.isNotEmpty)?
          Expanded(
                child: ListView.separated(
                itemCount: placesPredictedList.length,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context,index){
                   return PlacesPredictionTileDesign(
                     predictedPlaces: placesPredictedList[index],
                   );
                },
                 separatorBuilder: (BuildContext context, int index){
                  return Divider(
                    height: 0,
                    color: darkTheme? Colors.amber.shade400: Colors.blue,
                    thickness: 0,
                  );
           },

 )
          ):Container(),
              ],
        ),
      ),
    );
  }
}
