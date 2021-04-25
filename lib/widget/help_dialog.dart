import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AskHelpDialog extends StatefulWidget {
  AskHelpDialog({Key key}) : super(key: key);

  @override
  _AskHelpDialogState createState() => _AskHelpDialogState();
}

class _AskHelpDialogState extends State<AskHelpDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 8,
      backgroundColor: Colors.white,
      child: Container(
        height: 140,
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'Ask Help',
              style: GoogleFonts.lato(fontSize: 24),
            ),
            SizedBox(height: 4),
            Text(
              'Someone need your help',
              style: GoogleFonts.lato(fontSize: 18),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,
                  ),
                  child: Text(
                    'Accept',
                    style: GoogleFonts.lato(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.lato(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
