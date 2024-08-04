import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sharewheel/global/global.dart';
import 'package:sharewheel/screens/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailTextEditingController=TextEditingController();
  final _formKey= GlobalKey<FormState>();

  void _submit(){
    firebaseAuth.sendPasswordResetEmail(email: emailTextEditingController.text.trim()
    ).then((value) {
      Fluttertoast.showToast(msg: 'We have send you a email to recover password, please check email');
    }).onError((error, stackTrace) {
      Fluttertoast.showToast(msg: "Error occured: \n ${error.toString()}");
    });
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
          padding: const EdgeInsets.all(0),
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
                    padding: const EdgeInsets.fromLTRB(15, 20, 15, 50),
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
                                  hintText: "Reset Password link",
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: darkTheme? Colors.black45 :Colors.grey.shade200,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(40),
                                      borderSide:  BorderSide(
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
                                    "Already have an account?",
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
                                  Navigator.push(context, MaterialPageRoute(builder: (c)=>  LoginScreen()));
                                },
                                child: Text(
                                  "Login",
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
