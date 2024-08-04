import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sharewheel/screens/forgot_password_screen.dart';
import 'package:sharewheel/screens/register_screen.dart';
import 'package:sharewheel/splash_screen/splash_screen.dart';

import '../global/global.dart';
import 'main_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailTextEditingController=TextEditingController();
  final passwordTextEditingController=TextEditingController();
  bool _passwordVisible=false;
  final _formKey= GlobalKey<FormState>();

  void _submit() async{
    if(_formKey.currentState!.validate()){
      await firebaseAuth.signInWithEmailAndPassword(
    email: emailTextEditingController.text.trim(),
    password: passwordTextEditingController.text.trim()
    ).then((auth)async{
        DatabaseReference userRef=FirebaseDatabase.instance.ref().child("sharewheel");
        userRef.child(firebaseAuth.currentUser!.uid).once().then((value)async {

          final snap =value.snapshot;
          if(snap.value!=null){
            currentUser=auth.user;
            await Fluttertoast.showToast(msg: "Successfully Logged In");
            Navigator.push(context, MaterialPageRoute(builder: (c)=>  MainScreen()));
          }
          else{
            await Fluttertoast.showToast(msg: "No record exist with this email");
            firebaseAuth.signOut();
            Navigator.push(context, MaterialPageRoute(builder: (c)=>  SplashScreen()));
          }
        });
    }).catchError((errorMessage){
    Fluttertoast.showToast(msg: "Error occured: \n $errorMessage");
    });
    }
    else{
    Fluttertoast.showToast(msg: "Not all feilds are valid");
    }
  }

  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness==Brightness.dark;

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child:Scaffold(
        body: ListView(
          padding:  EdgeInsets.all(0),
          children: [
            Column(
              children: [
                Image.asset(darkTheme? 'images/sharewheel_login.jpeg' : 'images/city.jpg'),
                 SizedBox(height:20,),
                Text(
                  'Login',
                  style:TextStyle(
                    color : darkTheme ? Colors.amber.shade400 : Colors.blue,
                    fontSize:25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                    padding:  EdgeInsets.fromLTRB(15, 20, 15, 100),
                    child:Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Form(
                          key: _formKey,
                          child:Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children:[



                              TextFormField(
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(100)
                                ],
                                decoration: InputDecoration(
                                  hintText: "Email",
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: darkTheme? Colors.black45 :Colors.grey.shade200,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(40),
                                      borderSide: const BorderSide(
                                        width: 0,
                                        style: BorderStyle.none,

                                      )
                                  ),
                                  prefixIcon: Icon(Icons.person,color: darkTheme? Colors.amber.shade400 : Colors.grey,),
                                ),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (text){
                                  if(text==null||text.isEmpty){
                                    return 'Email can\'t be empty';
                                  }
                                  if(EmailValidator.validate(text)==true){
                                    return null;
                                  }
                                  if(text.length<2){
                                    return 'Please enter a valid email';
                                  }
                                  if(text.length>99){
                                    return 'Name cannot be more than 100 letter';
                                  }
                                  return null;
                                },
                                onChanged: (text)=>setState(() {
                                  emailTextEditingController.text=text;
                                }),
                              ),
                              const SizedBox(height: 20,),


                              TextFormField(
                                obscureText: !_passwordVisible,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(100)
                                ],
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: darkTheme? Colors.black45 :Colors.grey.shade200,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(40),
                                      borderSide: const BorderSide(
                                        width: 0,
                                        style: BorderStyle.none,

                                      )
                                  ),
                                  prefixIcon: Icon(Icons.person,color: darkTheme? Colors.amber.shade400 : Colors.grey,),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible ? Icons.visibility :Icons.visibility_off,
                                      color: darkTheme ? Colors.amber.shade400 : Colors.grey,
                                    ),
                                    onPressed: (){
                                      //update the state of password to visible
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });

                                    },
                                  ),
                                ),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (text){
                                  if(text==null||text.isEmpty){
                                    return 'Password can\'t be empty';
                                  }
                                  if(text.length<2){
                                    return 'Please enter a valid Password';
                                  }
                                  if(text.length>49){
                                    return 'Password cannot be more than 50 letter';
                                  }
                                  return null;
                                },
                                onChanged: (text)=>setState(() {
                                  passwordTextEditingController.text=text;
                                }),
                              ),
                              const SizedBox(height: 20,),



                              ElevatedButton(
                                style:ElevatedButton.styleFrom(
                                  foregroundColor: darkTheme ? Colors.black : Colors.white, backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  minimumSize: const Size(double.infinity,50),
                                ),
                                onPressed: (){
                                  _submit();
                                },
                                child: const Text(
                                  'Login',

                                  style: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),

                              ),
                              const SizedBox(height: 20,),


                              GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (c)=> const ForgotPasswordScreen()));
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20,),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Doesn't have an account",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(width: 20,),

                              GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (c)=> const RegisterScreen()));
                                },
                                child: Text(
                                  "Register",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  ),
                                ),
                              )

                            ],
                          ),
                        ),
                      ],
                    )
                )




              ],
            )
          ],
        ),
      ),
    );
  }
}
