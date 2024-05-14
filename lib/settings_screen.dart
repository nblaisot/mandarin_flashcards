import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool initialEnglish = false;  // Assume starting with English is default
  String emailBody = "Here are my learning stats.";  // Placeholder email body

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: Text('Start with English'),
            subtitle: Text('Toggle between starting flashcards in English or Mandarin'),
            value: initialEnglish,
            onChanged: (bool value) {
              setState(() {
                initialEnglish = value;
              });
            },
          ),
          ListTile(
            title: Text('Reset Progress'),
            leading: Icon(Icons.refresh),
            onTap: () {
              // Reset the progress logic
              print('Resetting progress...');
              // Implement the reset logic here
            },
          ),
          ListTile(
            title: Text('Export Data'),
            subtitle: Text('Export your learning statistics and send via email'),
            leading: Icon(Icons.email),
            onTap: () async {
              // Call function to handle data export and email
              await exportDataAndSendEmail();
            },
          ),
        ],
      ),
    );
  }

  Future<void> exportDataAndSendEmail() async {
    final String directory = (await getApplicationDocumentsDirectory()).path;
    final String path = '$directory/learning_stats.csv';

    // Create a test CSV file or load your stats here
    File csvFile = File(path);
    await csvFile.writeAsString("Word,Success Count,Failure Count\nHello,5,2\n");

    final Email email = Email(
      body: emailBody,
      subject: 'My Learning Stats',
      recipients: ['example@example.com'],
      attachmentPaths: [path],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      print('Email sent!');
    } catch (error) {
      print('Error sending email: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send email: $error'),
        ),
      );
    }
  }
}
