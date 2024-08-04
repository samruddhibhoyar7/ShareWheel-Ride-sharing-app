import 'package:firebase_auth/firebase_auth.dart';
import 'package:sharewheel/models/direction_details_info.dart';
import 'package:sharewheel/models/user_model.dart';

final FirebaseAuth firebaseAuth=FirebaseAuth.instance;
User? currentUser;
UserModel? userModelCurrentInfo;
DirectionDetailsInfo? tripDirectionDetailsInfo;
String cloudMessagingServerToken = "key=AAAA8EHMRFQ:APA91bHjMJPV57jU3m3q772ipgBWwHCy5hT-J0UkoQqUyuNG0FTsJdTrGwtQefRR_VtB5hR3P-jmucOcJswtkVLAkMhqZEYo3-3Hfm-nYfDkhmr47t87bmKwqYcTWUiqwco4nFrr3Eeb";
List driversList = [];
String driverRatings = "";
String userDropOffAddress="";
String driverCarDetails = "";
String driverName = "";
String driverPhone = "";
double countRatingStars = 0.0;
String titleStarsRating="";
String selectedVehicleType = "";
double totalFareAmount=0.0;