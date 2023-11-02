import 'dart:async';



import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Constant.dart';
import '../app/Demo_Localization.dart';
import 'String.dart';

const String isLogin = '${appName}isLogin';

setPrefrenceBool(String key, bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<bool> isNetworkAvailable() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(LAGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String languageCode = prefs.getString(LAGUAGE_CODE) ?? "en";
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  switch (languageCode) {
    case "en":
      return const Locale("en", 'US');
    case "zh":
      return const Locale("zh", "CN");
    case "es":
      return const Locale("es", "ES");
    case "hi":
      return const Locale("hi", "IN");
    case "ar":
      return const Locale("ar", "DZ");
    case "ru":
      return const Locale("ru", "RU");
    case "ja":
      return const Locale("ja", "JP");
    case "de":
      return const Locale("de", "DE");
    default:
      return const Locale("en", 'US');
  }
}

String? getTranslated(BuildContext context, String key) {
  return DemoLocalization.of(context)!.translate(key);
}



String getToken() {
  final claimSet = JwtClaim(
      issuer: issuerName,
      // maxAge: const Duration(minutes: 1),
      maxAge: const Duration(days: tokenExpireTime),
      issuedAt: DateTime.now().toUtc());

      String token = issueJwtHS256(claimSet, jwtKey);
      print("token is $token");
      return token;
}

Map<String, String> get headers => {
      "Authorization": 'Bearer ${getToken()}',
    };
