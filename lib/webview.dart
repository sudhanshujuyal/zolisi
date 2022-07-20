
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'Constant/constant.dart';
import 'Repository/app_repository.dart';
import 'model/appinfo.dart';

class Webview extends StatefulWidget {
  const Webview({Key? key}) : super(key: key);

  @override
  State<Webview> createState() => _WebviewState();
}

class _WebviewState extends State<Webview>
{
  late Future<AppInfo> appInfo;
  var iosVersion="1";
  var androidVersion="1";
  bool isChanged=false;
  WebViewController? _controller;
  bool skipupdate = false;

  final Completer<WebViewController> _controllerCompleter =
  Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    appInfo=AppRepository.getAppInfo();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);


  }

  Future<bool> _goBack(BuildContext context) async {
    if (await _controller!.canGoBack()) {
      _controller!.goBack();
      return Future.value(false);
    } else {
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog(
            title:const Text(Constants.exit,style: TextStyle(fontSize: 16),),

            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child:const Text(Constants.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child:const Text(Constants.yes),
              ),
            ],
          ));
      return Future.value(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:FutureBuilder<AppInfo>(
        future: appInfo,
        builder: (context, snapshot) {
          if (snapshot.hasData) {

            if(int.parse(snapshot.data!.message![0].iosAppVersionCode) > int.parse(iosVersion))
            {
              if(skipupdate){
                return WillPopScope(
                  onWillPop: () => _goBack(context),
                  child: Scaffold(

                    body: Container(
                      margin: const EdgeInsets.only(top: 32),

                      child: WebView(
                        initialUrl:'http://institutefortransport.com/',
                        onPageStarted: (String url){
                          const CircularProgressIndicator();
                        },
                        onProgress: (int progress){
                          print("WebView is Loading" + progress.toString());
                        },
                        onPageFinished: (String url){
                          const CircularProgressIndicator();
                        },
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated: (WebViewController webViewController) {
                          _controllerCompleter.future.then((value) => _controller = value);
                          _controllerCompleter.complete(webViewController);
                        },
                      ),
                    ),
                  ),

                );
              }else{
                return _showMyDialog(snapshot);
              }
              // iosVersion=snapshot.data!.message![0].iosAppVersionCode;


            } else {
              return WillPopScope(
                onWillPop: () => _goBack(context),
                child: Scaffold(

                  body: Container(
                    margin: const EdgeInsets.only(top: 32),

                    child: WebView(
                      initialUrl:'http://institutefortransport.com/',
                      // initialUrl:snapshot.data!.message![0].appLink,
                      javascriptMode: JavascriptMode.unrestricted,
                      onWebViewCreated: (WebViewController webViewController) {
                        _controllerCompleter.future.then((value) => _controller = value);
                        _controllerCompleter.complete(webViewController);
                      },
                    ),
                  ),
                ),

              );
            }

          }
          // return Text(snapshot.data!.message.toString());

          else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          // By default, show a loading spinner.
          return Center(child: Scaffold(
            body: Container(
              color: Colors.white,
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Image.asset("Assets/logo.png"),
              ),
            ),
          ));
        },
      ),
    );
  }

  Widget _showMyDialog([AsyncSnapshot<AppInfo>? snapshot])
  {
    return  Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey,
      child: CupertinoAlertDialog(

        title: const Text("Update Available"),
        content: Text("New Version : ${snapshot!.data!.message![0].appName}"),
        actions: <Widget>[
          CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: (){
                _launchURL(snapshot.data!.message![0].appStoreLink.toString());
              },
              child: const Text("Yes")
          ),
          CupertinoDialogAction(
              textStyle: const TextStyle(color: Colors.red),
              isDefaultAction: true,
              onPressed: () async {
                setState(() {
                  skipupdate = true;
                });
              },
              child: const Text("Skip")
          ),
        ],
      ),
    );

  }

  void _launchURL(String _url) async {
    if (!await launch(_url)) throw 'Could not launch $_url';
  }
}
