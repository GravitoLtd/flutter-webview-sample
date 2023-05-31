// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: WebViewExample());
  }
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebViewController controller;
  bool _showWebView = true;

  @override
  void initState() {
    super.initState();

    // #docregion webview_controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            print("err");
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterAppWebView',
        onMessageReceived: (JavaScriptMessage message) async {
          var messageData = jsonDecode(message.message);
          // Obtain shared preferences.
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          String messageType = messageData["type"];
          switch (messageType) {
            case "CMP-loaded":

              // this message will be fired when cmp will be loaded now app has to check it has previously stored consent
              // in native storage if yes then we need to send it to CMP else we need to send empty data
              final String? resultString = prefs.getString('cookieData');
              var storedData =
                  resultString != null ? jsonDecode(resultString) : null;
              print("cmplo");
              var message = {
                "type": "cookieData",
                "tcstring": storedData != null ? storedData["tcstring"] : null,
                "nontcfdata":
                    storedData != null ? storedData["nontcfdata"] : null
              };
              String jsonMessage = jsonEncode(message);

              controller.runJavaScript(' window.postMessage($jsonMessage)');

              break;
            case "close":
              setState(() {
                print("close");
                _showWebView = false;
              });
              break;
            case "save":

              //         messagedata will have following strucutre
              //          let onSaveMessageFlutter = {
              //   type: "save",
              //   tcstring: encodedString,
              //   currentstate: getCoreConfigDetails(),
              //   nontcfdata: nonTCFModel.Model,
              //   configversion: config.core.version,
              //   tcstringversion: tcModel.cmpVersion,
              //   inAppTCData: getInAppTCData(),
              // };

              // this message will be fired when there is save action perfomed on CMP ui inside webView,
              // data with this message should be stored in native storage
              // this is only for sample app, In production you will have to store keys in format specified here
              //https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20CMP%20API%20v2.md#in-app-details
              var d = {
                "tcstring": messageData["tcstring"],
                "nontcfdata": messageData["nontcfdata"],
              };
              await prefs.setString("cookieData", jsonEncode(d));
              break;

            default:
          }

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(message.message)),
          // );
        },
      )
      ..loadRequest(Uri.parse('ENTER_YOUR_URL'));

    // #enddocregion webview_controller
  }

  void clearAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("cookieData");
  }

  void openWebView() {
    print("openWeb");
    controller.reload();
  }

  // #docregion webview_widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('WebView Sample'), actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  openWebView();
                },
                child: const Icon(
                  Icons.edit,
                  size: 26.0,
                ),
              )),
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  clearAll();
                },
                child: const Icon(
                  Icons.delete,
                  size: 26.0,
                ),
              ))
        ]),
        body: WebViewWidget(controller: controller));
  }
  // #enddocregion webview_widget
}
