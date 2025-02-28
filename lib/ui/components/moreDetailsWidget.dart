import 'package:flutter/material.dart';
import 'package:yourapp/ui/pages/moreDetails.dart';

Widget MoreDetailsWideget(BuildContext context, String path) {
  return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MoreDetailsScreen(path: path)));
          },
          child: const Text(
            "More Details",
            style: TextStyle(color: Colors.white),
          )));
}
