import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('더보기'),

      ),
      body: Column(
        children: [
          SizedBox(height: 30.0,),
          InkWell(
            onTap: (){
              print('rate tap');
            },
            child: Container(
              height: 30.0,
              child: Row(
                children: [
                  SizedBox(width: 10.0,),
                  Icon(Icons.star),
                  SizedBox(width: 5.0),
                  Text('Rate'),
                ],
              ),
              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
            ),
          )
        ],
      ),
    );
  }
}
