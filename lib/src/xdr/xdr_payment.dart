// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_other.dart';
import 'xdr_account.dart';

class XdrPathPaymentStrictReceiveOp {
  XdrPathPaymentStrictReceiveOp(this._sendAsset, this._sendMax,
      this._destination, this._destAsset, this._destAmount, this._path);
  XdrAsset _sendAsset;
  XdrAsset get sendAsset => this._sendAsset;
  set sendAsset(XdrAsset value) => this._sendAsset = value;

  XdrBigInt64 _sendMax;
  XdrBigInt64 get sendMax => this._sendMax;
  set sendMax(XdrBigInt64 value) => this._sendMax = value;

  XdrMuxedAccount _destination;
  XdrMuxedAccount get destination => this._destination;
  set destination(XdrMuxedAccount value) => this._destination = value;

  XdrAsset _destAsset;
  XdrAsset get destAsset => this._destAsset;
  set destAsset(XdrAsset value) => this._destAsset = value;

  XdrBigInt64 _destAmount;
  XdrBigInt64 get destAmount => this._destAmount;
  set destAmount(XdrBigInt64 value) => this._destAmount = value;

  List<XdrAsset> _path;
  List<XdrAsset> get path => this._path;
  set path(List<XdrAsset> value) => this._path = value;

  static void encode(XdrDataOutputStream stream,
      XdrPathPaymentStrictReceiveOp encodedPathPaymentOp) {
    XdrAsset.encode(stream, encodedPathPaymentOp.sendAsset);
    XdrBigInt64.encode(stream, encodedPathPaymentOp.sendMax);
    XdrMuxedAccount.encode(stream, encodedPathPaymentOp.destination);
    XdrAsset.encode(stream, encodedPathPaymentOp.destAsset);
    XdrBigInt64.encode(stream, encodedPathPaymentOp.destAmount);
    int pathSize = encodedPathPaymentOp.path.length;
    stream.writeInt(pathSize);
    for (int i = 0; i < pathSize; i++) {
      XdrAsset.encode(stream, encodedPathPaymentOp.path[i]);
    }
  }

  static XdrPathPaymentStrictReceiveOp decode(XdrDataInputStream stream) {
    XdrAsset sendAsset = XdrAsset.decode(stream);
    XdrBigInt64 sendMax = XdrBigInt64.decode(stream);
    XdrMuxedAccount destination = XdrMuxedAccount.decode(stream);
    XdrAsset destAsset = XdrAsset.decode(stream);
    XdrBigInt64 destAmount = XdrBigInt64.decode(stream);

    int pathsize = stream.readInt();
    List<XdrAsset> path = List<XdrAsset>.empty(growable: true);
    for (int i = 0; i < pathsize; i++) {
      path.add(XdrAsset.decode(stream));
    }
    return XdrPathPaymentStrictReceiveOp(
        sendAsset, sendMax, destination, destAsset, destAmount, path);
  }
}

class XdrPathPaymentStrictSendOp {
  XdrPathPaymentStrictSendOp(this._sendAsset, this._sendMax, this._destination,
      this._destAsset, this._destAmount, this._path);
  XdrAsset _sendAsset;
  XdrAsset get sendAsset => this._sendAsset;
  set sendAsset(XdrAsset value) => this._sendAsset = value;

  XdrBigInt64 _sendMax;
  XdrBigInt64 get sendMax => this._sendMax;
  set sendMax(XdrBigInt64 value) => this._sendMax = value;

  XdrMuxedAccount _destination;
  XdrMuxedAccount get destination => this._destination;
  set destination(XdrMuxedAccount value) => this._destination = value;

  XdrAsset _destAsset;
  XdrAsset get destAsset => this._destAsset;
  set destAsset(XdrAsset value) => this._destAsset = value;

  XdrBigInt64 _destAmount;
  XdrBigInt64 get destAmount => this._destAmount;
  set destAmount(XdrBigInt64 value) => this._destAmount = value;

  List<XdrAsset> _path;
  List<XdrAsset> get path => this._path;
  set path(List<XdrAsset> value) => this._path = value;

  static void encode(XdrDataOutputStream stream,
      XdrPathPaymentStrictSendOp encodedPathPaymentOp) {
    XdrAsset.encode(stream, encodedPathPaymentOp.sendAsset);
    XdrBigInt64.encode(stream, encodedPathPaymentOp.sendMax);
    XdrMuxedAccount.encode(stream, encodedPathPaymentOp.destination);
    XdrAsset.encode(stream, encodedPathPaymentOp.destAsset);
    XdrBigInt64.encode(stream, encodedPathPaymentOp.destAmount);
    int pathSize = encodedPathPaymentOp.path.length;
    stream.writeInt(pathSize);
    for (int i = 0; i < pathSize; i++) {
      XdrAsset.encode(stream, encodedPathPaymentOp.path[i]);
    }
  }

  static XdrPathPaymentStrictSendOp decode(XdrDataInputStream stream) {
    XdrAsset sendAsset = XdrAsset.decode(stream);
    XdrBigInt64 sendMax = XdrBigInt64.decode(stream);
    XdrMuxedAccount destination = XdrMuxedAccount.decode(stream);
    XdrAsset destAsset = XdrAsset.decode(stream);
    XdrBigInt64 destAmount = XdrBigInt64.decode(stream);

    int pathsize = stream.readInt();
    List<XdrAsset> path = List<XdrAsset>.empty(growable: true);
    for (int i = 0; i < pathsize; i++) {
      path.add(XdrAsset.decode(stream));
    }

    return XdrPathPaymentStrictSendOp(
        sendAsset, sendMax, destination, destAsset, destAmount, path);
  }
}

class XdrPathPaymentStrictReceiveResult {
  XdrPathPaymentStrictReceiveResult(this._code);
  XdrPathPaymentStrictReceiveResultCode _code;
  XdrPathPaymentStrictReceiveResultCode get discriminant => this._code;
  set discriminant(XdrPathPaymentStrictReceiveResultCode value) =>
      this._code = value;

  XdrPathPaymentResultSuccess? _success;
  XdrPathPaymentResultSuccess? get success => this._success;
  set success(XdrPathPaymentResultSuccess? value) => this._success = value;

  XdrAsset? _noIssuer;
  XdrAsset? get noIssuer => this._noIssuer;
  set noIssuer(XdrAsset? value) => this._noIssuer = value;

  static void encode(XdrDataOutputStream stream,
      XdrPathPaymentStrictReceiveResult encodedPathPaymentResult) {
    stream.writeInt(encodedPathPaymentResult.discriminant.value);
    switch (encodedPathPaymentResult.discriminant) {
      case XdrPathPaymentStrictReceiveResultCode
          .PATH_PAYMENT_STRICT_RECEIVE_SUCCESS:
        XdrPathPaymentResultSuccess.encode(
            stream, encodedPathPaymentResult.success!);
        break;
      case XdrPathPaymentStrictReceiveResultCode
          .PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER:
        XdrAsset.encode(stream, encodedPathPaymentResult.noIssuer!);
        break;
      default:
        break;
    }
  }

  static XdrPathPaymentStrictReceiveResult decode(XdrDataInputStream stream) {
    XdrPathPaymentStrictReceiveResult decodedPathPaymentResult =
        XdrPathPaymentStrictReceiveResult(
            XdrPathPaymentStrictReceiveResultCode.decode(stream));
    switch (decodedPathPaymentResult.discriminant) {
      case XdrPathPaymentStrictReceiveResultCode
          .PATH_PAYMENT_STRICT_RECEIVE_SUCCESS:
        decodedPathPaymentResult.success =
            XdrPathPaymentResultSuccess.decode(stream);
        break;
      case XdrPathPaymentStrictReceiveResultCode
          .PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER:
        decodedPathPaymentResult.noIssuer = XdrAsset.decode(stream);
        break;
      default:
        break;
    }
    return decodedPathPaymentResult;
  }
}

class XdrPathPaymentStrictSendResult {
  XdrPathPaymentStrictSendResult(this._code);
  XdrPathPaymentStrictSendResultCode _code;
  XdrPathPaymentStrictSendResultCode get discriminant => this._code;
  set discriminant(XdrPathPaymentStrictSendResultCode value) =>
      this._code = value;

  XdrPathPaymentResultSuccess? _success;
  XdrPathPaymentResultSuccess? get success => this._success;
  set success(XdrPathPaymentResultSuccess? value) => this._success = value;

  XdrAsset? _noIssuer;
  XdrAsset? get noIssuer => this._noIssuer;
  set noIssuer(XdrAsset? value) => this._noIssuer = value;

  static void encode(XdrDataOutputStream stream,
      XdrPathPaymentStrictSendResult encodedPathPaymentResult) {
    stream.writeInt(encodedPathPaymentResult.discriminant.value);
    switch (encodedPathPaymentResult.discriminant) {
      case XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SUCCESS:
        XdrPathPaymentResultSuccess.encode(
            stream, encodedPathPaymentResult.success!);
        break;
      case XdrPathPaymentStrictSendResultCode
          .PATH_PAYMENT_STRICT_SEND_NO_ISSUER:
        XdrAsset.encode(stream, encodedPathPaymentResult.noIssuer!);
        break;
      default:
        break;
    }
  }

  static XdrPathPaymentStrictSendResult decode(XdrDataInputStream stream) {
    XdrPathPaymentStrictSendResult decodedPathPaymentResult =
        XdrPathPaymentStrictSendResult(
            XdrPathPaymentStrictSendResultCode.decode(stream));
    switch (decodedPathPaymentResult.discriminant) {
      case XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SUCCESS:
        decodedPathPaymentResult.success =
            XdrPathPaymentResultSuccess.decode(stream);
        break;
      case XdrPathPaymentStrictSendResultCode
          .PATH_PAYMENT_STRICT_SEND_NO_ISSUER:
        decodedPathPaymentResult.noIssuer = XdrAsset.decode(stream);
        break;
      default:
        break;
    }
    return decodedPathPaymentResult;
  }
}

class XdrPathPaymentStrictReceiveResultCode {
  final _value;
  const XdrPathPaymentStrictReceiveResultCode._internal(this._value);
  toString() => 'PathPaymentStrictReceiveResultCode.$_value';
  XdrPathPaymentStrictReceiveResultCode(this._value);
  get value => this._value;

  /// Success.
  static const PATH_PAYMENT_STRICT_RECEIVE_SUCCESS =
      const XdrPathPaymentStrictReceiveResultCode._internal(0);

  ///  Bad input.
  static const PATH_PAYMENT_STRICT_RECEIVE_MALFORMED =
      const XdrPathPaymentStrictReceiveResultCode._internal(-1);

  /// Not enough funds in source account.
  static const PATH_PAYMENT_STRICT_RECEIVE_UNDERFUNDED =
      const XdrPathPaymentStrictReceiveResultCode._internal(-2);

  /// No trust line on source account.
  static const PATH_PAYMENT_STRICT_RECEIVE_SRC_NO_TRUST =
      const XdrPathPaymentStrictReceiveResultCode._internal(-3);

  /// Source not authorized to transfer.
  static const PATH_PAYMENT_STRICT_RECEIVE_SRC_NOT_AUTHORIZED =
      const XdrPathPaymentStrictReceiveResultCode._internal(-4);

  /// Destination account does not exist.
  static const PATH_PAYMENT_STRICT_RECEIVE_NO_DESTINATION =
      const XdrPathPaymentStrictReceiveResultCode._internal(-5);

  /// Dest missing a trust line for asset.
  static const PATH_PAYMENT_STRICT_RECEIVE_NO_TRUST =
      const XdrPathPaymentStrictReceiveResultCode._internal(-6);

  /// Dest not authorized to hold asset.
  static const PATH_PAYMENT_STRICT_RECEIVE_NOT_AUTHORIZED =
      const XdrPathPaymentStrictReceiveResultCode._internal(-7);

  /// Dest would go above their limit.
  static const PATH_PAYMENT_STRICT_RECEIVE_LINE_FULL =
      const XdrPathPaymentStrictReceiveResultCode._internal(-8);

  /// Missing issuer on one asset.
  static const PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER =
      const XdrPathPaymentStrictReceiveResultCode._internal(-9);

  /// Not enough offers to satisfy path.
  static const PATH_PAYMENT_STRICT_RECEIVE_TOO_FEW_OFFERS =
      const XdrPathPaymentStrictReceiveResultCode._internal(-10);

  /// Would cross one of its own offers.
  static const PATH_PAYMENT_STRICT_RECEIVE_OFFER_CROSS_SELF =
      const XdrPathPaymentStrictReceiveResultCode._internal(-11);

  /// Could not satisfy sendmax.
  static const PATH_PAYMENT_STRICT_RECEIVE_OVER_SENDMAX =
      const XdrPathPaymentStrictReceiveResultCode._internal(-12);

  static XdrPathPaymentStrictReceiveResultCode decode(
      XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return PATH_PAYMENT_STRICT_RECEIVE_SUCCESS;
      case -1:
        return PATH_PAYMENT_STRICT_RECEIVE_MALFORMED;
      case -2:
        return PATH_PAYMENT_STRICT_RECEIVE_UNDERFUNDED;
      case -3:
        return PATH_PAYMENT_STRICT_RECEIVE_SRC_NO_TRUST;
      case -4:
        return PATH_PAYMENT_STRICT_RECEIVE_SRC_NOT_AUTHORIZED;
      case -5:
        return PATH_PAYMENT_STRICT_RECEIVE_NO_DESTINATION;
      case -6:
        return PATH_PAYMENT_STRICT_RECEIVE_NO_TRUST;
      case -7:
        return PATH_PAYMENT_STRICT_RECEIVE_NOT_AUTHORIZED;
      case -8:
        return PATH_PAYMENT_STRICT_RECEIVE_LINE_FULL;
      case -9:
        return PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER;
      case -10:
        return PATH_PAYMENT_STRICT_RECEIVE_TOO_FEW_OFFERS;
      case -11:
        return PATH_PAYMENT_STRICT_RECEIVE_OFFER_CROSS_SELF;
      case -12:
        return PATH_PAYMENT_STRICT_RECEIVE_OVER_SENDMAX;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrPathPaymentStrictReceiveResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrPathPaymentStrictSendResultCode {
  final _value;
  const XdrPathPaymentStrictSendResultCode._internal(this._value);
  toString() => 'PathPaymentStrictSendResultCode.$_value';
  XdrPathPaymentStrictSendResultCode(this._value);
  get value => this._value;

  /// Success.
  static const PATH_PAYMENT_STRICT_SEND_SUCCESS =
      const XdrPathPaymentStrictSendResultCode._internal(0);

  ///  Bad input.
  static const PATH_PAYMENT_STRICT_SEND_MALFORMED =
      const XdrPathPaymentStrictSendResultCode._internal(-1);

  /// Not enough funds in source account.
  static const PATH_PAYMENT_STRICT_SEND_UNDERFUNDED =
      const XdrPathPaymentStrictSendResultCode._internal(-2);

  /// No trust line on source account.
  static const PATH_PAYMENT_STRICT_SEND_SRC_NO_TRUST =
      const XdrPathPaymentStrictSendResultCode._internal(-3);

  /// Source not authorized to transfer.
  static const PATH_PAYMENT_STRICT_SEND_SRC_NOT_AUTHORIZED =
      const XdrPathPaymentStrictSendResultCode._internal(-4);

  /// Destination account does not exist.
  static const PATH_PAYMENT_STRICT_SEND_NO_DESTINATION =
      const XdrPathPaymentStrictSendResultCode._internal(-5);

  /// Dest missing a trust line for asset.
  static const PATH_PAYMENT_STRICT_SEND_NO_TRUST =
      const XdrPathPaymentStrictSendResultCode._internal(-6);

  /// Dest not authorized to hold asset.
  static const PATH_PAYMENT_STRICT_SEND_NOT_AUTHORIZED =
      const XdrPathPaymentStrictSendResultCode._internal(-7);

  /// Dest would go above their limit.
  static const PATH_PAYMENT_STRICT_SEND_LINE_FULL =
      const XdrPathPaymentStrictSendResultCode._internal(-8);

  /// Missing issuer on one asset.
  static const PATH_PAYMENT_STRICT_SEND_NO_ISSUER =
      const XdrPathPaymentStrictSendResultCode._internal(-9);

  /// Not enough offers to satisfy path.
  static const PATH_PAYMENT_STRICT_SEND_TOO_FEW_OFFERS =
      const XdrPathPaymentStrictSendResultCode._internal(-10);

  /// Would cross one of its own offers.
  static const PATH_PAYMENT_STRICT_SEND_OFFER_CROSS_SELF =
      const XdrPathPaymentStrictSendResultCode._internal(-11);

  /// Could not satisfy destMin.
  static const PATH_PAYMENT_STRICT_SEND_UNDER_DESTMIN =
      const XdrPathPaymentStrictSendResultCode._internal(-12);

  static XdrPathPaymentStrictSendResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return PATH_PAYMENT_STRICT_SEND_SUCCESS;
      case -1:
        return PATH_PAYMENT_STRICT_SEND_MALFORMED;
      case -2:
        return PATH_PAYMENT_STRICT_SEND_UNDERFUNDED;
      case -3:
        return PATH_PAYMENT_STRICT_SEND_SRC_NO_TRUST;
      case -4:
        return PATH_PAYMENT_STRICT_SEND_SRC_NOT_AUTHORIZED;
      case -5:
        return PATH_PAYMENT_STRICT_SEND_NO_DESTINATION;
      case -6:
        return PATH_PAYMENT_STRICT_SEND_NO_TRUST;
      case -7:
        return PATH_PAYMENT_STRICT_SEND_NOT_AUTHORIZED;
      case -8:
        return PATH_PAYMENT_STRICT_SEND_LINE_FULL;
      case -9:
        return PATH_PAYMENT_STRICT_SEND_NO_ISSUER;
      case -10:
        return PATH_PAYMENT_STRICT_SEND_TOO_FEW_OFFERS;
      case -11:
        return PATH_PAYMENT_STRICT_SEND_OFFER_CROSS_SELF;
      case -12:
        return PATH_PAYMENT_STRICT_SEND_UNDER_DESTMIN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrPathPaymentStrictSendResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrPathPaymentResultSuccess {
  XdrPathPaymentResultSuccess(this._offers, this._last);
  List<XdrClaimAtom> _offers;
  List<XdrClaimAtom> get offers => this._offers;
  set offers(List<XdrClaimAtom> value) => this._offers = value;

  XdrSimplePaymentResult _last;
  XdrSimplePaymentResult get last => this._last;
  set last(XdrSimplePaymentResult value) => this._last = value;

  static void encode(XdrDataOutputStream stream,
      XdrPathPaymentResultSuccess encodedPathPaymentResultSuccess) {
    int offerssize = encodedPathPaymentResultSuccess.offers.length;
    stream.writeInt(offerssize);
    for (int i = 0; i < offerssize; i++) {
      XdrClaimAtom.encode(stream, encodedPathPaymentResultSuccess.offers[i]);
    }
    XdrSimplePaymentResult.encode(stream, encodedPathPaymentResultSuccess.last);
  }

  static XdrPathPaymentResultSuccess decode(XdrDataInputStream stream) {
    int offerssize = stream.readInt();
    List<XdrClaimAtom> offers = List<XdrClaimAtom>.empty(growable: true);
    for (int i = 0; i < offerssize; i++) {
      offers.add(XdrClaimAtom.decode(stream));
    }

    XdrSimplePaymentResult last = XdrSimplePaymentResult.decode(stream);

    return XdrPathPaymentResultSuccess(offers, last);
  }
}

class XdrSimplePaymentResult {
  XdrSimplePaymentResult(this._destination, this._asset, this._amount);
  XdrMuxedAccount _destination;
  XdrMuxedAccount get destination => this._destination;
  set destination(XdrMuxedAccount value) => this._destination = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  XdrInt64 _amount;
  XdrInt64 get amount => this._amount;
  set amount(XdrInt64 value) => this._amount = value;

  static void encode(XdrDataOutputStream stream,
      XdrSimplePaymentResult encodedSimplePaymentResult) {
    XdrMuxedAccount.encode(stream, encodedSimplePaymentResult.destination);
    XdrAsset.encode(stream, encodedSimplePaymentResult.asset);
    XdrInt64.encode(stream, encodedSimplePaymentResult.amount);
  }

  static XdrSimplePaymentResult decode(XdrDataInputStream stream) {
    XdrMuxedAccount destination = XdrMuxedAccount.decode(stream);
    XdrAsset asset = XdrAsset.decode(stream);
    XdrInt64 amount = XdrInt64.decode(stream);
    return XdrSimplePaymentResult(destination, asset, amount);
  }
}

class XdrPaymentOp {
  XdrPaymentOp(this._destination, this._asset, this._amount);

  XdrMuxedAccount _destination;
  XdrMuxedAccount get destination => this._destination;
  set destination(XdrMuxedAccount value) => this._destination = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  XdrBigInt64 _amount;
  XdrBigInt64 get amount => this._amount;
  set amount(XdrBigInt64 value) => this._amount = value;

  static void encode(
      XdrDataOutputStream stream, XdrPaymentOp encodedPaymentOp) {
    XdrMuxedAccount.encode(stream, encodedPaymentOp.destination);
    XdrAsset.encode(stream, encodedPaymentOp.asset);
    XdrBigInt64.encode(stream, encodedPaymentOp.amount);
  }

  static XdrPaymentOp decode(XdrDataInputStream stream) {
    XdrMuxedAccount destination = XdrMuxedAccount.decode(stream);
    XdrAsset asset = XdrAsset.decode(stream);
    XdrBigInt64 amount = XdrBigInt64.decode(stream);
    return XdrPaymentOp(destination, asset, amount);
  }
}

class XdrPaymentResult {
  XdrPaymentResult(this._code);
  XdrPaymentResultCode _code;
  XdrPaymentResultCode get discriminant => this._code;
  set discriminant(XdrPaymentResultCode value) => this._code = value;

  static void encode(
      XdrDataOutputStream stream, XdrPaymentResult encodedPaymentResult) {
    stream.writeInt(encodedPaymentResult.discriminant.value);
    switch (encodedPaymentResult.discriminant) {
      case XdrPaymentResultCode.PAYMENT_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrPaymentResult decode(XdrDataInputStream stream) {
    XdrPaymentResult decodedPaymentResult =
        XdrPaymentResult(XdrPaymentResultCode.decode(stream));
    switch (decodedPaymentResult.discriminant) {
      case XdrPaymentResultCode.PAYMENT_SUCCESS:
        break;
      default:
        break;
    }
    return decodedPaymentResult;
  }
}

class XdrPaymentResultCode {
  final _value;
  const XdrPaymentResultCode._internal(this._value);
  toString() => 'PaymentResultCode.$_value';
  XdrPaymentResultCode(this._value);
  get value => this._value;

  /// Payment successfully completed.
  static const PAYMENT_SUCCESS = const XdrPaymentResultCode._internal(0);

  /// Bad input.
  static const PAYMENT_MALFORMED = const XdrPaymentResultCode._internal(-1);

  /// Not enough funds in source account.
  static const PAYMENT_UNDERFUNDED = const XdrPaymentResultCode._internal(-2);

  /// No trust line on source account.
  static const PAYMENT_SRC_NO_TRUST = const XdrPaymentResultCode._internal(-3);

  /// Source not authorized to transfer.
  static const PAYMENT_SRC_NOT_AUTHORIZED =
      const XdrPaymentResultCode._internal(-4);

  /// Destination account does not exist.
  static const PAYMENT_NO_DESTINATION =
      const XdrPaymentResultCode._internal(-5);

  /// Destination missing a trust line for asset.
  static const PAYMENT_NO_TRUST = const XdrPaymentResultCode._internal(-6);

  /// Destination not authorized to hold asset.
  static const PAYMENT_NOT_AUTHORIZED =
      const XdrPaymentResultCode._internal(-7);

  /// Destination would go above their limit.
  static const PAYMENT_LINE_FULL = const XdrPaymentResultCode._internal(-8);

  /// Missing issuer on asset.
  static const PAYMENT_NO_ISSUER = const XdrPaymentResultCode._internal(-9);

  static XdrPaymentResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return PAYMENT_SUCCESS;
      case -1:
        return PAYMENT_MALFORMED;
      case -2:
        return PAYMENT_UNDERFUNDED;
      case -3:
        return PAYMENT_SRC_NO_TRUST;
      case -4:
        return PAYMENT_SRC_NOT_AUTHORIZED;
      case -5:
        return PAYMENT_NO_DESTINATION;
      case -6:
        return PAYMENT_NO_TRUST;
      case -7:
        return PAYMENT_NOT_AUTHORIZED;
      case -8:
        return PAYMENT_LINE_FULL;
      case -9:
        return PAYMENT_NO_ISSUER;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrPaymentResultCode value) {
    stream.writeInt(value.value);
  }
}
