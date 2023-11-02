import 'dart:async';
import 'dart:core';
import 'package:rushbuy/Helper/Constant.dart';
import 'package:rushbuy/Helper/Session.dart';
import 'package:rushbuy/Provider/SettingProvider.dart';
import 'package:rushbuy/Screen/Map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/String.dart';
import '../Model/User.dart';
import '../ui/widgets/SimpleAppBar.dart';
import 'Cart.dart';
import 'HomePage.dart';

class AddAddress extends StatefulWidget {
  final bool? update;
  final int? index;
  Function? updateState;

  AddAddress({Key? key, this.update, this.index, this.updateState})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateAddress();
  }
}

String? latitude, longitude, state, country;

class StateAddress extends State<AddAddress> with TickerProviderStateMixin {
  String? name,
      mobile,
      city,
      area,
      address,
      pincode,
      landmark,
      altMob,
      type = 'Home',
      isDefault,
      selectedArea = '',
      selectedCity = '',
      cityName,
      areaName;
  bool checkedDefault = false, isArea = false;
  bool _isProgress = false;
  bool _isLoadProcess = false;

  // StateSetter? areaState, cityState;

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  List<User> cityList = [];
  List<User> areaList = [];
  List<User> areaSearchList = [];
  List<User> citySearchLIst = [];
  bool cityLoading = true, areaLoading = true;
  TextEditingController? nameC,
      mobileC,
      pincodeC,
      addressC,
      landmarkC,
      stateC,
      countryC,
      altMobC,
      cityC,
      areaC;
  int? selectedType = 1;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  FocusNode? nameFocus,
      monoFocus,
      almonoFocus,
      addFocus,
      landFocus,
      locationFocus,
      cityFocus,
      areaFocus = FocusNode();
  User? selArea;
  int? selAreaPos = -1, selCityPos = -1;
  int cityOffset = 0, areaOffset = 0, cityTotal = 0, areaTotal = 0;
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final ScrollController _cityScrollController = ScrollController();
  final ScrollController _areaScrollController = ScrollController();
  bool cityEnable = false, areaEnable = false;
  bool? isLoadingMoreCity, isLoadingMoreArea;

  @override
  void initState() {
    super.initState();

    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
    _cityScrollController.addListener(_scrollListener);
    _areaScrollController.addListener(_areaScrollListener);
    callApi();
    mobileC = TextEditingController();
    nameC = TextEditingController();
    altMobC = TextEditingController();
    pincodeC = TextEditingController();
    addressC = TextEditingController();
    stateC = TextEditingController();
    countryC = TextEditingController();
    landmarkC = TextEditingController();
    cityC = TextEditingController();
    areaC = TextEditingController();

    if (widget.update!) {
      User item = addressList[widget.index!];

      mobileC!.text = item.mobile!;
      nameC!.text = item.name!;
      altMobC!.text = item.altMob!;
      landmarkC!.text = item.landmark!;
      pincodeC!.text = item.pincode!;
      addressC!.text = item.address!;
      stateC!.text = item.state!;
      countryC!.text = item.country!;
      stateC!.text = item.state!;
      latitude = item.latitude;
      longitude = item.longitude;
      selectedCity = item.city!;
      selectedArea = item.area!;
      cityC!.text = item.city!;
      areaC!.text = item.area!;

      type = item.type;
      if (item.cityId != "0") {
        selCityPos = int.parse(item.areaId!);
      } else {
        if (IS_SHIPROCKET_ON == "1") {
          cityEnable = true;
        }
      }
      city = item.cityId;

      if (item.areaId != "0") {
        selAreaPos = int.parse(item.cityId!);
      } else {
        if (IS_SHIPROCKET_ON == "1") {
          areaEnable = true;
        }
      }
      area = item.areaId;

      if (type!.toLowerCase() == HOME.toLowerCase()) {
        selectedType = 1;
      } else if (type!.toLowerCase() == OFFICE.toLowerCase()) {
        selectedType = 2;
      } else {
        selectedType = 3;
      }

      checkedDefault = item.isDefault == '1' ? true : false;
    } else {
      getCurrentLoc();
    }
  }

  _scrollListener() async {
    if (_cityScrollController.offset >=
            _cityScrollController.position.maxScrollExtent &&
        !_cityScrollController.position.outOfRange) {
      if (mounted) {
        //setState(() {});

        setState(() {
          isLoadingMoreCity = true;
          _isProgress = true;
        });
        if (cityOffset < cityTotal) getCities(false);
        // });
      }
    }
  }

  _areaScrollListener() async {
    if (_areaScrollController.offset >=
            _areaScrollController.position.maxScrollExtent &&
        !_areaScrollController.position.outOfRange) {
      if (mounted) {
        setState(() {
          isLoadingMoreArea = true;
        });
        if (areaOffset < areaTotal) getArea(city, false, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key: _scaffoldKey,
      appBar: getSimpleAppBar(getTranslated(context, 'ADDRESS_LBL')!, context),
      body: _isNetworkAvail
          ? Stack(children: <Widget>[
              _showContent(),
              showCircularProgress(_isLoadProcess, colors.primary),
            ])
          : noInternet(context),
    );
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(const Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                          builder: (BuildContext context) => super.widget));
                } else {
                  await buttonController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      checkNetwork();
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();

    if (form.validate()) {
      if ((!cityEnable && IS_SHIPROCKET_ON != "1") &&
          (city == null || city!.isEmpty)) {
        // if (cityName == null) {
        setSnackbar(getTranslated(context, 'cityWarning')!, context);
        // }
      } else if ((IS_SHIPROCKET_ON != "1") &&
          (!areaEnable || !cityEnable) &&
          (area == null || area!.isEmpty)) {
        // if (areaName == null) {
        setSnackbar(getTranslated(context, 'areaWarning')!, context);
        // }
      } else if (latitude == null || longitude == null) {
        setSnackbar(getTranslated(context, 'locationWarning')!, context);
      } else {
        return true;
      }
    }

    return false;
  }

  Future<void> checkNetwork() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      addNewAddress();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
        await buttonController!.reverse();
      });
    }
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode? nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  setUserName() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            focusNode: nameFocus,
            controller: nameC,
            textCapitalization: TextCapitalization.words,
            validator: (val) => validateUserName(
                val!,
                getTranslated(context, 'USER_REQUIRED'),
                getTranslated(context, 'USER_LENGTH')),
            onSaved: (String? value) {
              name = value;
            },
            onFieldSubmitted: (v) {
              _fieldFocusChange(context, nameFocus!, monoFocus);
            },
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            decoration: InputDecoration(
                label: Text(getTranslated(context, 'NAME_LBL')!),
                fillColor: Theme.of(context).colorScheme.white,
                isDense: true,
                hintText: getTranslated(context, 'NAME_LBL'),
                border: InputBorder.none),
          ),
        ),
      ),
    );
  }

  setMobileNo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.number,
            controller: mobileC,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            focusNode: monoFocus,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            validator: (val) => validateMob(
                val!,
                getTranslated(context, 'MOB_REQUIRED'),
                getTranslated(context, 'VALID_MOB')),
            onSaved: (String? value) {
              mobile = value;
            },
            onFieldSubmitted: (v) {
              _fieldFocusChange(context, monoFocus!, almonoFocus);
            },
            decoration: InputDecoration(
                label: Text(getTranslated(context, 'MOBILEHINT_LBL')!),
                fillColor: Theme.of(context).colorScheme.white,
                isDense: true,
                hintText: getTranslated(context, 'MOBILEHINT_LBL'),
                border: InputBorder.none),
          ),
        ),
      ),
    );
  }

  areaDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            //  areaState = setStater;
            return WillPopScope(
              onWillPop: () async {
                //  setStater() {
                areaOffset = 0;
                _areaController.clear();
                //  }
                setStater(() {});
                return true;
              },
              child: AlertDialog(
                contentPadding: const EdgeInsets.all(0.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      5.0,
                    ),
                  ),
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                      child: Text(
                        getTranslated(context, 'AREASELECT_LBL')!,
                        style: Theme.of(this.context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: Theme.of(context).colorScheme.fontColor),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              controller: _areaController,
                              autofocus: false,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                              ),
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                                hintText: getTranslated(context, 'SEARCH_LBL'),
                                hintStyle: TextStyle(
                                    color: colors.primary.withOpacity(0.5)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: IconButton(
                              onPressed: () async {
                                setStater(() {
                                  isLoadingMoreArea = true;
                                });

                                await getArea(city, true, true);
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.search,
                                size: 20,
                              )),
                        )
                      ],
                    ),
                    Divider(color: Theme.of(context).colorScheme.lightBlack),
                    areaLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 50.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Flexible(
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: SingleChildScrollView(
                                controller: _areaScrollController,
                                child: Column(
                                  children: [
                                    if (IS_SHIPROCKET_ON == "1")
                                      InkWell(
                                        onTap: () {
                                          setStater(() {
                                            selAreaPos = -1;

                                            selArea = null;

                                            pincodeC!.clear();
                                            selectedArea = null;

                                            areaEnable = true;
                                            Navigator.of(context).pop();
                                            setState(() {});
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                              getTranslated(
                                                  context, 'OTHER_AREA_LBL')!,
                                              textAlign: TextAlign.start,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary),
                                            ),
                                          ),
                                        ),
                                      ),
                                    areaSearchList.isNotEmpty
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: getAreaList(setStater))
                                        : Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20.0),
                                            child: getNoItem(context),
                                          ),
                                    showCircularProgress(
                                        isLoadingMoreArea!, colors.primary),
                                  ],
                                ),
                              ),
                            ),
                          )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  cityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            // cityState = setStater;

            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                    child: Text(
                      getTranslated(context, 'CITYSELECT_LBL')!,
                      style: Theme.of(this.context)
                          .textTheme
                          .titleMedium!
                          .copyWith(
                              color: Theme.of(context).colorScheme.fontColor),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: _cityController,
                            autofocus: false,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                            ),
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                              hintText: getTranslated(context, 'SEARCH_LBL'),
                              hintStyle: TextStyle(
                                  color: colors.primary.withOpacity(0.5)),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: IconButton(
                            onPressed: () async {
                              setStater(() {
                                isLoadingMoreCity = true;
                              });
                              setState(() {});

                              await getCities(true);
                            },
                            icon: const Icon(
                              Icons.search,
                              size: 20,
                            )),
                      )
                    ],
                  ),
                  cityLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 50.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : (citySearchLIst.isNotEmpty)
                          ? Flexible(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: SingleChildScrollView(
                                  controller: _cityScrollController,
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (IS_SHIPROCKET_ON == "1")
                                            InkWell(
                                              onTap: () {
                                                setStater(() {
                                                  isArea = false;
                                                  selAreaPos = null;
                                                  selArea = null;
                                                  pincodeC!.text = '';
                                                  cityEnable = true;
                                                  selCityPos = -1;
                                                  Navigator.of(context).pop();
                                                });
                                                setState(() {});
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Text(
                                                    getTranslated(context,
                                                        'OTHER_CITY_LBL')!,
                                                    textAlign: TextAlign.start,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall!
                                                        .copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: getCityList(setStater),
                                          ),
                                          Center(
                                            child: showCircularProgress(
                                                isLoadingMoreCity!,
                                                colors.primary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: getNoItem(context),
                            )
                ],
              ),
            );
          },
        );
      },
    );
  }

  getAreaList(StateSetter stateSetter) {
    return areaSearchList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  areaOffset = 0;
                  _areaController.clear();

                  stateSetter(
                    () {
                      selAreaPos = index;

                      areaEnable = false;
                      areaC!.clear();
                      areaName = null;
                      selArea = areaSearchList[selAreaPos!];
                      area = selArea!.id;
                      selectedArea = areaSearchList[selAreaPos!].name!;
                      pincodeC!.text = selArea!.pincode!;
                    },
                  );

                  //getArea(city, false, true);
                  Navigator.of(context).pop();
                  setState(() {});
                }
              },
              child: SizedBox(
                width: double.maxFinite,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    areaSearchList[index].name!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  getCityList(StateSetter setStater) {
    return citySearchLIst
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  setStater(
                    () {
                      isArea = false;
                      selCityPos = index;
                      selAreaPos = null;
                      selArea = null;
                      pincodeC!.text = '';
                      cityC!.clear();
                      cityName = null;
                      cityEnable = false;
                      Navigator.of(context).pop();
                    },
                  );

                  city = citySearchLIst[selCityPos!].id;

                  selectedCity = citySearchLIst[selCityPos!].name;
                  getArea(city, true, true);
                  setState(() {});
                }
                // }
              },
              child: SizedBox(
                width: double.maxFinite,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    citySearchLIst[index].name!,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: citySearchLIst[index].id == "0"
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.fontColor),
                  ),
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  setCities() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
            ),
            child: GestureDetector(
              child: InputDecorator(
                  decoration: InputDecoration(
                    fillColor: Theme.of(context).colorScheme.white,
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getTranslated(context, 'CITYSELECT_LBL')!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                                selCityPos != null && selCityPos != -1
                                    ? selectedCity!
                                    : cityEnable && IS_SHIPROCKET_ON == "1"
                                        ? getTranslated(
                                            context, 'OTHER_CITY_LBL')!
                                        : '',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor)),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_right)
                    ],
                  )),
              onTap: () {
                cityDialog();
              },
            )),
      ),
    );
  }

  setArea() {
    if (!cityEnable) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
              ),
              child: GestureDetector(
                child: InputDecorator(
                    decoration: InputDecoration(
                        fillColor: Theme.of(context).colorScheme.white,
                        isDense: true,
                        border: InputBorder.none),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                getTranslated(context, 'AREASELECT_LBL')!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                  selAreaPos != null && selAreaPos != -1
                                      ? selectedArea!
                                      : areaEnable && IS_SHIPROCKET_ON == "1"
                                          ? getTranslated(
                                              context, 'OTHER_AREA_LBL')!
                                          : '',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor)),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_right),
                      ],
                    )),
                onTap: () {
                  if (selCityPos != null && selCityPos != -1) {
                    areaDialog();
                  }
                },
              )),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget setCityName() {
    if (cityEnable && IS_SHIPROCKET_ON == "1") {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                  ),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor),
                    focusNode: cityFocus,
                    controller: cityC,
                    validator: (val) => validateField(
                        val!, getTranslated(context, 'FIELD_REQUIRED')),
                    onSaved: (String? value) {
                      cityName = value;
                    },
                    decoration: InputDecoration(
                      label: Text(getTranslated(context, 'CITY_NAME_LBL')!),
                      fillColor: Theme.of(context).colorScheme.white,
                      isDense: true,
                      hintText: getTranslated(context, 'CITY_NAME_LBL')!,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget setAreaName() {
    if (IS_SHIPROCKET_ON == "1" && areaEnable || cityEnable) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                  ),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor),
                    focusNode: areaFocus,
                    controller: areaC,
                    validator: (val) => validateField(
                        val!, getTranslated(context, 'FIELD_REQUIRED')),
                    onSaved: (String? value) {
                      areaName = value;
                    },
                    decoration: InputDecoration(
                      label: Text(getTranslated(context, 'AREA_NAME_LBL')!),
                      hintStyle:
                          Theme.of(context).textTheme.titleSmall!.copyWith(),
                      fillColor: Theme.of(context).colorScheme.white,
                      isDense: true,
                      hintText: getTranslated(context, 'AREA_NAME_LBL')!,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  setAddress() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: Theme.of(context).colorScheme.fontColor),
                  focusNode: addFocus,
                  controller: addressC,
                  validator: (val) => validateField(
                      val!, getTranslated(context, 'FIELD_REQUIRED')),
                  onSaved: (String? value) {
                    address = value;
                  },
                  onFieldSubmitted: (v) {
                    _fieldFocusChange(context, addFocus!, locationFocus);
                  },
                  decoration: InputDecoration(
                    label: Text(getTranslated(context, 'ADDRESS_LBL')!),
                    fillColor: Theme.of(context).colorScheme.white,
                    isDense: true,
                    hintText: getTranslated(context, 'ADDRESS_LBL'),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.my_location,
                        color: colors.primary,
                      ),
                      focusNode: locationFocus,
                      onPressed: () async {
                        LocationPermission permission;

                        permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                        }
                        Position position = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high);
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => Map(
                                      latitude:
                                          latitude == null || latitude == ''
                                              ? position.latitude
                                              : double.parse(latitude!),
                                      longitude:
                                          longitude == null || longitude == ''
                                              ? position.longitude
                                              : double.parse(longitude!),
                                      from:
                                          getTranslated(context, 'ADDADDRESS'),
                                    )));
                        if (mounted) setState(() {});
                        List<Placemark> placemark =
                            await placemarkFromCoordinates(
                                double.parse(latitude!),
                                double.parse(longitude!));

                        var address;
                        address = placemark[0].name;
                        address = address + ',' + placemark[0].subLocality;
                        address = address + ',' + placemark[0].locality;

                        state = placemark[0].administrativeArea;
                        country = placemark[0].country;

                        if (mounted) {
                          setState(() {
                            countryC!.text = country!;
                            stateC!.text = state!;
                            addressC!.text = address;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  setPincode() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
            ),
            child: TextFormField(
              keyboardType: TextInputType.number,
              controller: pincodeC,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              validator: (val) =>
                  validateField(val!, getTranslated(context, 'FIELD_REQUIRED')),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSaved: (String? value) {},
              decoration: InputDecoration(
                  label: Text(getTranslated(context, 'PINCODEHINT_LBL')!),
                  fillColor: Theme.of(context).colorScheme.white,
                  isDense: true,
                  hintText: getTranslated(context, 'PINCODEHINT_LBL'),
                  border: InputBorder.none),
            )),
      ),
    );
  }

  Future<void> callApi() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      await getCities(false);
      if (widget.update! && addressList[widget.index!].cityId != "0") {
        getArea(addressList[widget.index!].cityId, false, false);
      }
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      });
    }
  }

  Future<void> getCities(bool isSearchCity) async {
    try {
      var parameter = {
        LIMIT: perPage.toString(),
        OFFSET: cityOffset.toString(),
      };

      if (isSearchCity) {
        parameter[SEARCH] = _cityController.text;
        parameter[OFFSET] = '0';
        cityTotal = 0;
        cityOffset = 0;
        cityList.clear();
        cityLoading = true;
        citySearchLIst.clear();
        //  if (mounted && cityState != null) cityState!(() {});
        if (mounted) setState(() {});
      }
      apiBaseHelper.postAPICall(getCitiesApi, parameter).then((getdata) async {
        bool error = getdata['error'];
        String? msg = getdata['message'];
        cityTotal = int.parse(getdata["total"]);
        if (!error) {
          if (cityOffset < cityTotal) {
            var data = getdata['data'];
            cityList =
                (data as List).map((data) => User.fromJson(data)).toList();

            citySearchLIst.addAll(cityList);

            cityOffset += perPage;
          } else {}
        } else {
          if (msg != null) {
            setSnackbar(msg, context);
          }
        }
        cityLoading = false;
        isLoadingMoreCity = false;
        _isProgress = false;

        if (mounted) setState(() {});

        if (widget.update!) {
          selCityPos = citySearchLIst
              .indexWhere((f) => f.id == addressList[widget.index!].cityId);

          if (selCityPos == -1) {
            selCityPos = null;
          } else {
            selectedCity = citySearchLIst[selCityPos!].name!;
          }
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

  Future<void> getArea(String? city, bool clear, bool isSearchArea) async {
    try {
      var data = {
        ID: city,
        OFFSET: areaOffset.toString(),
        LIMIT: perPage.toString()
      };

      if (isSearchArea) {
        data[SEARCH] = _areaController.text;
        data[OFFSET] = '0';
        // areaTotal = 0;
        // areaOffset = 0;
        // areaList.clear();
        // areaLoading = true;
        areaSearchList.clear();
        // if (mounted && areaState != null) areaState!(() {});
        //if (mounted) setState(() {});
      }
      apiBaseHelper.postAPICall(getAreaByCityApi, data).then((getdata) {
        bool error = getdata['error'];
        String? msg = getdata['message'];
        areaTotal = int.parse(getdata["total"]);
        if (!error) {
          if (areaOffset < areaTotal) {
            var data = getdata['data'];
            areaList.clear();
            if (clear) {
              area = null;
              selArea = null;
            }
            areaList =
                (data as List).map((data) => User.fromJson(data)).toList();

            areaSearchList.addAll(areaList);

            if (widget.update!) {
              for (User item in addressList) {
                for (int i = 0; i < areaSearchList.length; i++) {
                  if (areaSearchList[i].id == item.areaId) {
                    selArea = areaSearchList[i];
                    selAreaPos = i;
                    selectedArea = areaSearchList[selAreaPos!].name!;
                  }
                }
              }
            }
            areaOffset += perPage;
          } else {}
        } else {
          if (msg != null) {
            setSnackbar(msg, context);
          }
        }
        areaLoading = false;
        isLoadingMoreArea = false;

        isArea = true;

        if (mounted) setState(() {});
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

  setLandmark() {
    return TextFormField(
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      focusNode: landFocus,
      controller: landmarkC,
      style: Theme.of(context)
          .textTheme
          .titleSmall!
          .copyWith(color: Theme.of(context).colorScheme.fontColor),
      validator: (val) =>
          validateField(val!, getTranslated(context, 'FIELD_REQUIRED')),
      onSaved: (String? value) {
        landmark = value;
      },
      decoration: const InputDecoration(
        hintText: LANDMARK,
      ),
    );
  }

  setStateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: stateC,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            readOnly: false,
            onChanged: (v) => setState(() {
              state = v;
            }),
            onSaved: (String? value) {
              state = value;
            },
            decoration: InputDecoration(
                label: Text(getTranslated(context, 'STATE_LBL')!),
                fillColor: Theme.of(context).colorScheme.white,
                isDense: true,
                hintText: getTranslated(context, 'STATE_LBL'),
                border: InputBorder.none),
          ),
        ),
      ),
    );
  }

  setCountry() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: countryC,
            readOnly: false,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            onSaved: (String? value) {
              country = value;
            },
            validator: (val) =>
                validateField(val!, getTranslated(context, 'FIELD_REQUIRED')),
            decoration: InputDecoration(
                label: Text(getTranslated(context, 'COUNTRY_LBL')!),
                fillColor: Theme.of(context).colorScheme.white,
                isDense: true,
                hintText: getTranslated(context, 'COUNTRY_LBL'),
                border: InputBorder.none),
          ),
        ),
      ),
    );
  }

  Future<void> addNewAddress() async {
    if (mounted) {
      setState(() {
        _isLoadProcess = true;
      });
    }

    try {
      var data = {
        USER_ID: context.read<SettingProvider>().userId,
        NAME: name,
        MOBILE: mobile,
        // PINCODE: pincodeC!.text,
        ADDRESS: address,
        STATE: state,
        COUNTRY: country,
        TYPE: type,
        ISDEFAULT: checkedDefault.toString() == 'true' ? '1' : '0',
        LATITUDE: latitude,
        LONGITUDE: longitude
      };
      if (widget.update!) data[ID] = addressList[widget.index!].id;
      if (cityName != null) {
        data["city_name"] = cityName;
        data[CITY_ID] = "0";
      } else {
        data[CITY_ID] = city;
        data["city_name"] = selectedCity;
      }
      if (areaName != null) {
        data[AREA_ID] = "0";
        data["area_name"] = areaName;
      } else {
        data[AREA_ID] = area;
        data["area_name"] = selectedArea;
        //data[PINCODE]=pincodeC!.text;
      }
      data["pincode_name"] = pincodeC!.text;
      apiBaseHelper
          .postAPICall(
              widget.update! ? updateAddressApi : getAddAddressApi, data)
          .then((getdata) async {
        bool error = getdata['error'];
        String? msg = getdata['message'];

        await buttonController!.reverse();

        if (!error) {
          var data = getdata['data'];

          if (widget.update!) {
            User value = User.fromAddress(data[0]);

            addressList[widget.index!] = value;
            if (checkedDefault.toString() == 'true' ||
                addressList.length == 1) {
              for (User i in addressList) {
                i.isDefault = '0';
              }

              addressList[widget.index!].isDefault = '1';
              if (isUseWallet == true) {
                totalPrice = totalPrice + (usedBal - delCharge);
                isUseWallet = false;
                payMethod = null;
                usedBal = 0;
              }
              if (IS_SHIPROCKET_ON == "0") {
                if (!ISFLAT_DEL) {
                  if (oriPrice <
                      double.parse(addressList[selectedAddress!].freeAmt!)) {
                    delCharge = double.parse(
                        addressList[selectedAddress!].deliveryCharge!);
                  } else {
                    delCharge = 0;
                  }
                }
              }

              selectedAddress = widget.index;
              selAddress = addressList[widget.index!].id;
              if (IS_SHIPROCKET_ON == "0") {
                if (!ISFLAT_DEL) {
                  if (oriPrice <
                      double.parse(addressList[selectedAddress!].freeAmt!)) {
                    delCharge = double.parse(
                        addressList[selectedAddress!].deliveryCharge!);
                  } else {
                    delCharge = 0;
                  }
                }
              }
            }
          } else {
            User value = User.fromAddress(data[0]);
            addressList.add(value);

            if (checkedDefault.toString() == 'true' ||
                addressList.length == 1) {
              for (User i in addressList) {
                i.isDefault = '0';
              }

              addressList[widget.index!].isDefault = '1';
              if (IS_SHIPROCKET_ON == "0") {
                if (!ISFLAT_DEL && addressList.length != 1) {
                  if (oriPrice <
                      double.parse(addressList[selectedAddress!].freeAmt!)) {
                    delCharge = double.parse(
                        addressList[selectedAddress!].deliveryCharge!);
                  } else {
                    delCharge = 0;
                  }
                }
              }

              selectedAddress = widget.index;
              selAddress = addressList[widget.index!].id;
              if (IS_SHIPROCKET_ON == "0") {
                if (!ISFLAT_DEL) {
                  if (totalPrice <
                      double.parse(addressList[selectedAddress!].freeAmt!)) {
                    delCharge = double.parse(
                        addressList[selectedAddress!].deliveryCharge!);
                  } else {
                    delCharge = 0;
                  }
                }
              }
            }
          }

          if (mounted) {
            setState(() {
              _isLoadProcess = false;
            });
          }
          if (widget.updateState != null) {
            widget.updateState!();
          }
          Navigator.of(context).pop();
        } else {
          setSnackbar(msg!, context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    mobileC?.dispose();
    nameC?.dispose();
    stateC?.dispose();
    countryC?.dispose();
    altMobC?.dispose();
    landmarkC?.dispose();
    addressC!.dispose();
    pincodeC?.dispose();

    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  typeOfAddress() {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: InkWell(
                child: Row(
                  children: [
                    Radio(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      groupValue: selectedType,
                      activeColor: Theme.of(context).colorScheme.fontColor,
                      value: 1,
                      onChanged: (dynamic val) {
                        if (mounted) {
                          setState(() {
                            selectedType = val;
                            type = HOME;
                          });
                        }
                      },
                    ),
                    Expanded(child: Text(getTranslated(context, 'HOME_LBL')!))
                  ],
                ),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      selectedType = 1;
                      type = HOME;
                    });
                  }
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                child: Row(
                  children: [
                    Radio(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      groupValue: selectedType,
                      activeColor: Theme.of(context).colorScheme.fontColor,
                      value: 2,
                      onChanged: (dynamic val) {
                        if (mounted) {
                          setState(() {
                            selectedType = val;
                            type = OFFICE;
                          });
                        }
                      },
                    ),
                    Expanded(child: Text(getTranslated(context, 'OFFICE_LBL')!))
                  ],
                ),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      selectedType = 2;
                      type = OFFICE;
                    });
                  }
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                child: Row(
                  children: [
                    Radio(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      groupValue: selectedType,
                      activeColor: Theme.of(context).colorScheme.fontColor,
                      value: 3,
                      onChanged: (dynamic val) {
                        if (mounted) {
                          setState(() {
                            selectedType = val;
                            type = OTHER;
                          });
                        }
                      },
                    ),
                    Expanded(child: Text(getTranslated(context, 'OTHER_LBL')!))
                  ],
                ),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      selectedType = 3;
                      type = OTHER;
                    });
                  }
                },
              ),
            )
          ],
        ));
  }

  defaultAdd() {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: SwitchListTile(
          value: checkedDefault,
          activeColor: Theme.of(context).colorScheme.primary,
          dense: true,
          onChanged: (newValue) {
            if (mounted) {
              setState(() {
                checkedDefault = newValue;
              });
            }
          },
          title: Text(
            getTranslated(context, 'DEFAULT_ADD')!,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.lightBlack,
                fontWeight: FontWeight.bold),
          ),
        ));
  }

  _showContent() {
    return Form(
        key: _formkey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: <Widget>[
                      setUserName(),
                      setMobileNo(),
                      setAddress(),
                      setCities(),
                      setCityName(),
                      setArea(),
                      setAreaName(),
                      setPincode(),
                      setStateField(),
                      setCountry(),
                      typeOfAddress(),
                      defaultAdd(),
                    ],
                  ),
                ),
              ),
            ),
            saveButton(getTranslated(context, 'SAVE_LBL')!, () {
              validateAndSubmit();
            }),
          ],
        ));
  }

  Future<void> areaSearch(String searchText) async {
    areaSearchList.clear();
    for (int i = 0; i < areaList.length; i++) {
      User map = areaList[i];

      if (map.name!.toLowerCase().contains(searchText)) {
        areaSearchList.add(map);
      }
    }

    //if (mounted) areaState!(() {});
  }

  Future<void> getCurrentLoc() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    latitude = position.latitude.toString();
    longitude = position.longitude.toString();

    List<Placemark> placemark = await GeocodingPlatform.instance
        .placemarkFromCoordinates(
            double.parse(latitude!), double.parse(longitude!),
            localeIdentifier: 'en');

    state = placemark[0].administrativeArea;
    country = placemark[0].country;

    if (mounted) {
      setState(() {
        countryC!.text = country!;
        stateC!.text = state!;
      });
    }
  }

  Widget saveButton(String title, VoidCallback? onBtnSelected) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: MaterialButton(
              height: 45.0,
              textColor: Theme.of(context).colorScheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              onPressed: onBtnSelected,
              color: colors.primary,
              child: Text(
                title,
                style: const TextStyle(color: colors.whiteTemp, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
