import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 25,
          right: 25,
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:const[
              Text('Welcome,',style: TextStyle(
                fontSize: 22,
                color:Colors.white,
                fontWeight:FontWeight.bold
              ),),
              SizedBox(height:5),
              Text("what's on you mind?",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              )
              ,)
            ]
          ),
          CircleAvatar(
            child: Image.asset(
              'assets/avatar.png',
              fit: BoxFit.cover,
            ),
          )
        ]));
  }
}
