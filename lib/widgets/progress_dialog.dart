import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {

  String? message;
  ProgressDialog({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        margin:   EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [

               SizedBox(width: 6,),

               CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),

              const SizedBox(width: 26.0,),
        Expanded(
            child:Text(
              message!,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),

            ),

        )

          ],

        ),
      ),
    );
  }
}