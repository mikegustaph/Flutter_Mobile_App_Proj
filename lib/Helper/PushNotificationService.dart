// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:rushbuy/Model/Section_Model.dart';
import 'package:rushbuy/Provider/SettingProvider.dart';
import 'package:rushbuy/Screen/Dashboard.dart';
import 'package:rushbuy/Screen/MyOrder.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Model/FlashSaleModel.dart';
import '../Provider/FlashSaleProvider.dart';
import '../Screen/All_Category.dart';
import '../Screen/Chat.dart';
import '../Screen/Customer_Support.dart';
import '../Screen/FlashSaleProductList.dart';
import '../Screen/HomePage.dart';
import '../Screen/My_Wallet.dart';
import '../Screen/Product_DetailNew.dart';
import '../Screen/Splash.dart';
import '../main.dart';
import '../ui/styles/DesignConfig.dart';
import 'Constant.dart';
import 'Session.dart';
import 'String.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
FirebaseMessaging messaging = FirebaseMessaging.instance;

//Future<void> backgroundMessage(RemoteMessage message) async {}
backgroundMessage(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print(
      'notification(${notificationResponse.id}) action tapped: ${notificationResponse.actionId} with payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

class PushNotificationService {
  late BuildContext context;
  final PageController pageController;

  PushNotificationService(
      {required this.context, required this.pageController});

  Future initialise() async {
    iOSPermission();
    /*  messaging.getToken().then((token) async {
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);

      if (settingsProvider.userId != null && settingsProvider.userId != "") {
        registerToken(token);
      }
    });*/

    messaging.getToken().then(
      (token) async {
        SettingProvider settingsProvider =
            Provider.of<SettingProvider>(context, listen: false);

        String getToken = await settingsProvider.getPrefrence(FCMTOKEN) ?? '';

        if (token != getToken && token != null) {
          registerToken(token);
        }
      },
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');
    /* const IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings();
    const MacOSInitializationSettings initializationSettingsMacOS = MacOSInitializationSettings();*/

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        /* didReceiveLocalNotificationStream.add(
          ReceivedNotification(
            id: id,
            title: title,
            body: body,
            payload: payload,
          ),
        );*/
      },
    );

    /*const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);*/

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    /*flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      print("payload*****$payload");
      selectNotificationPayload(payload);
    });*/
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        print("notification response ${notificationResponse.payload}");
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationPayload(notificationResponse.payload!);

            break;
          case NotificationResponseType.selectedNotificationAction:
            print(
                "notification-action-id--->${notificationResponse.actionId}==${notificationResponse.payload}");

            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: backgroundMessage,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);

      var data = message.notification!;
      var title = data.title.toString();
      var body = data.body.toString();
      var image = message.data['image'] ?? '';

      var type = message.data['type'] ?? '';
      var id = '';
      id = message.data['type_id'] ?? '';
      var urlLink = message.data['link'] ?? '';

      print(
          "message on data****${data.title.toString()}******${data.body.toString()}****${message.data['image']}******${message.data['type']}*******${message.data['type_id']}");

      if (type == "ticket_status") {
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => const CustomerSupport()));
      } else if (type == "ticket_message") {
        if (CUR_TICK_ID == id) {
          if (chatstreamdata != null) {
            var parsedJson = json.decode(message.data['chat']);
            parsedJson = parsedJson[0];

            Map<String, dynamic> sendata = {
              "id": parsedJson[ID],
              "title": parsedJson[TITLE],
              "message": parsedJson[MESSAGE],
              "user_id": parsedJson[USER_ID],
              "name": parsedJson[NAME],
              "date_created": parsedJson[DATE_CREATED],
              "attachments": parsedJson["attachments"]
            };
            var chat = {};

            chat["data"] = sendata;
            if (parsedJson[USER_ID] != settingsProvider.userId) {
              chatstreamdata!.sink.add(jsonEncode(chat));
            }
          }
        } else {
          if (image != null && image != 'null' && image != '') {
            generateImageNotication(title, body, image, type, id, urlLink);
          } else {
            generateSimpleNotication(title, body, type, id, urlLink);
          }
        }
      } else if (image != null && image != 'null' && image != '') {
        generateImageNotication(title, body, image, type, id, urlLink);
      } else {
        generateSimpleNotication(title, body, type, id, urlLink);
      }
    });

    messaging.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        print("message******${message.data.toString()}");
        // bool back = await getPrefrenceBool(ISFROMBACK);
        bool back = await Provider.of<SettingProvider>(context, listen: false)
            .getPrefrenceBool(ISFROMBACK);

        if (back) {
          var type = message.data['type'] ?? '';
          var id = '';
          id = message.data['type_id'] ?? '';
          String urlLink = message.data['link'] ?? "";
          print("URL is $urlLink and type is $type");
          if (type == "products") {
            getProduct(id, 0, 0, true);
          } else if (type == "categories") {
            Navigator.push(
                context,
                (CupertinoPageRoute(
                    builder: (context) => const AllCategory())));
          } else if (type == "wallet") {
            Navigator.push(context,
                (CupertinoPageRoute(builder: (context) => const MyWallet())));
          } else if (type == 'order') {
            Navigator.push(context,
                (CupertinoPageRoute(builder: (context) => const MyOrder())));
          } else if (type == "ticket_message") {
            Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => Chat(
                        id: id,
                        status: "",
                      )),
            );
          } else if (type == "ticket_status") {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const CustomerSupport()));
          } else if (type == "notification_url") {
            print("here we are");
            String url = urlLink.toString();
            try {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              } else {
                throw 'Could not launch $url';
              }
            } catch (e) {
              throw 'Something went wrong';
            }
          } else if (type == "flash_sale") {
            getFlashSale(id);
          } else {
            Navigator.push(context,
                (CupertinoPageRoute(builder: (context) => const Splash())));
          }
          Provider.of<SettingProvider>(context, listen: false)
              .setPrefrenceBool(ISFROMBACK, false);
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("message on opened app listen******${message.data.toString()}");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var type = message.data['type'] ?? '';
      var id = '';

      id = message.data['type_id'] ?? '';

      String urlLink = message.data['link'];

      if (type == "products") {
        getProduct(id, 0, 0, true);
      } else if (type == "categories") {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const AllCategory()),
        );
      } else if (type == "wallet") {
        Navigator.push(context,
            (CupertinoPageRoute(builder: (context) => const MyWallet())));
      } else if (type == 'order') {
        Navigator.push(context,
            (CupertinoPageRoute(builder: (context) => const MyOrder())));
      } else if (type == "ticket_message") {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => Chat(
                    id: id,
                    status: "",
                  )),
        );
      } else if (type == "ticket_status") {
        Navigator.push(context,
            CupertinoPageRoute(builder: (context) => const CustomerSupport()));
      } else if (type == "notification_url") {
        String url = urlLink.toString();
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          } else {
            throw 'Could not launch $url';
          }
        } catch (e) {
          throw 'Something went wrong';
        }
      } else if (type == "flash_sale") {
        getFlashSale(id);
      } else {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => const Dashboard(
                  //sharedPreferences: prefs,
                  )),
        );
      }
      Provider.of<SettingProvider>(context, listen: false)
          .setPrefrenceBool(ISFROMBACK, false);
    });
  }

  void iOSPermission() async {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void registerToken(String? token) async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    var parameter = {
      FCM_ID: token,
    };
    if (settingsProvider.userId != null) {
      parameter[USER_ID] = settingsProvider.userId;
    }

    Response response =
        await post(updateFcmApi, body: parameter, headers: headers)
            .timeout(const Duration(seconds: timeOut));

    var getdata = json.decode(response.body);

    print("param noti fcm***$parameter");

    print("value notification****$getdata");

    if (getdata['error'] == false) {
      print("fcm token****$token");
      settingsProvider.setPrefrence(FCMTOKEN, token!);
    }
  }

  /* void _registerToken(String? token) async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    var parameter = {USER_ID: settingsProvider.userId, FCM_ID: token};

    Response response =
        await post(updateFcmApi, body: parameter, headers: headers)
            .timeout(const Duration(seconds: timeOut));

    var getdata = json.decode(response.body);
  }*/

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    try {
      var parameter = {
        ID: id,
      };

      Response response =
          await post(getProductApi, headers: headers, body: parameter)
              .timeout(const Duration(seconds: timeOut));
      var getdata = json.decode(response.body);
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];

        List<Product> items = [];

        items = (data as List).map((data) => Product.fromJson(data)).toList();
        currentHero = notifyHero;
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) => ProductDetail(
                  index: int.parse(id),
                  id: items[0].id!,
                  secPos: secPos,
                  list: list,
                )));
      } else {}
    } on Exception {}
  }

  void getFlashSale(String id) {
    try {
      apiBaseHelper.postAPICall(getFlashSaleApi, {}).then((getdata) {
        bool error = getdata["error"];

        context.read<FlashSaleProvider>().removeSaleList();

        if (!error) {
          var data = getdata["data"];

          List<FlashSaleModel> saleList = (data as List)
              .map((data) => FlashSaleModel.fromJson(data))
              .toList();
          context.read<FlashSaleProvider>().setSaleList(saleList);
          int index = saleList.indexWhere((element) => element.id == id);
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => FlashProductList(
                  index: index,
                ),
              ));
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  selectNotificationPayload(String? payload) async {
    if (payload != null) {
      print("all details $payload");
      List<String> pay = payload.split(",");
      print("pay is $pay");
      print("payload ${pay[0]}");
      if (pay[0] == "products") {
        getProduct(pay[1], 0, 0, true);
      } else if (pay[0] == "categories") {
        Future.delayed(Duration.zero, () {
          pageController.animateToPage(1,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut);
        });
      } else if (pay[0] == "wallet") {
        Navigator.push(context,
            (CupertinoPageRoute(builder: (context) => const MyWallet())));
      } else if (pay[0] == 'order') {
        Navigator.push(context,
            (CupertinoPageRoute(builder: (context) => const MyOrder())));
      } else if (pay[0] == "ticket_message") {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => Chat(
                    id: pay[1],
                    status: "",
                  )),
        );
      } else if (pay[0] == "ticket_status") {
        Navigator.push(context,
            CupertinoPageRoute(builder: (context) => const CustomerSupport()));
      } else if (pay[0] == "notification_url") {
        String url = pay[2].toString();
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          } else {
            throw 'Could not launch $url';
          }
        } catch (e) {
          throw 'Something went wrong';
        }
      } else if (pay[0] == "flash_sale") {
        getFlashSale(pay[1]);
      } else {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const Splash()),
        );
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => MyApp(sharedPreferences: prefs)),
      );
    }
  }
}

Future<dynamic> myForgroundMessageHandler(RemoteMessage message) async {
  setPrefrenceBool(ISFROMBACK, true);

  return Future<void>.value();
}

Future<String> _downloadAndSaveImage(String url, String fileName) async {
  var directory = await getApplicationDocumentsDirectory();
  var filePath = '${directory.path}/$fileName';
  var response = await http.get(Uri.parse(url));

  var file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

Future<void> generateImageNotication(String title, String msg, String image,
    String type, String id, String url) async {
  var largeIconPath = await _downloadAndSaveImage(image, 'largeIcon');
  var bigPicturePath = await _downloadAndSaveImage(image, 'bigPicture');
  var bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: msg,
      htmlFormatSummaryText: true);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'big text channel id', 'big text channel name',
      channelDescription: 'big text channel description',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation);
  var platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin
      .show(0, title, msg, platformChannelSpecifics, payload: "$type,$id,$url");
}

const DarwinNotificationDetails darwinNotificationDetails =
    DarwinNotificationDetails(
  categoryIdentifier: "",
);

Future<void> generateSimpleNotication(
    String title, String msg, String type, String id, String url) async {
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'your channel id', 'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker');
  //var iosDetail = const IOSNotificationDetails();

  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: darwinNotificationDetails);
  await flutterLocalNotificationsPlugin
      .show(0, title, msg, platformChannelSpecifics, payload: "$type,$id,$url");
}
