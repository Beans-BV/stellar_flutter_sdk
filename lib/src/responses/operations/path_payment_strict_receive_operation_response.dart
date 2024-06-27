// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../transaction_response.dart';

/// Represents PathPaymentStrictReceive operation response.
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/path-payment-strict-receive" target="_blank">Path Payment Strict Receive Object</a>
class PathPaymentStrictReceiveOperationResponse extends OperationResponse {
  String amount;
  String? sourceAmount;
  String? sourceMax;
  String from;
  String to;

  String? fromMuxed;
  String? fromMuxedId;
  String? toMuxed;
  String? toMuxedId;

  String assetType;
  String? assetCode;
  String? assetIssuer;

  String sourceAssetType;
  String? sourceAssetCode;
  String? sourceAssetIssuer;
  List<Asset> path;

  PathPaymentStrictReceiveOperationResponse(
      this.amount,
      this.sourceAmount,
      this.sourceMax,
      this.from,
      this.fromMuxed,
      this.fromMuxedId,
      this.to,
      this.toMuxed,
      this.toMuxedId,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.sourceAssetType,
      this.sourceAssetCode,
      this.sourceAssetIssuer,
      this.path,
      super.links,
      super.id,
      super.pagingToken,
      super.transactionSuccessful,
      super.sourceAccount,
      super.sourceAccountMuxed,
      super.sourceAccountMuxedId,
      super.type,
      super.type_i,
      super.createdAt,
      super.transactionHash,
      super.transaction,
      super.sponsor);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  Asset get sourceAsset {
    if (sourceAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(sourceAssetCode!, sourceAssetIssuer!);
    }
  }

  factory PathPaymentStrictReceiveOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      PathPaymentStrictReceiveOperationResponse(
          json['amount'],
          json['source_amount'],
          json['source_max'],
          json['from'],
          json['from_muxed'],
          json['from_muxed_id'],
          json['to'],
          json['to_muxed'],
          json['to_muxed_id'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['source_asset_type'],
          json['source_asset_code'],
          json['source_asset_issuer'],
          List<Asset>.from(json['path'].map((e) => Asset.fromJson(e))),
          OperationResponseLinks.fromJson(json['_links']),
          json['id'],
          json['paging_token'],
          json['transaction_successful'],
          json['source_account'],
          json['source_account_muxed'],
          json['source_account_muxed_id'],
          json['type'],
          json['type_i'],
          json['created_at'],
          json['transaction_hash'],
          json['transaction'] == null
              ? null
              : TransactionResponse.fromJson(json['transaction']),
          json['sponsor']);
}
