// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
/// 礼物模型
public class NEVoiceRoomGiftModel: NSObject {
  /// 发送者账号
  public var sendAccout: String = ""
  /// 发送者昵称
  public var sendNick: String = ""
  /// 礼物编号
  public var giftId: Int = 0
  internal init(_ rewardMsg: _NEVoiceRoomRewardMessage) {
    sendAccout = rewardMsg.senderUserUuid ?? ""
    sendNick = rewardMsg.rewarderUserName ?? ""
    giftId = rewardMsg.giftId ?? 0
  }
}

@objcMembers
/// 礼物模型
public class NEVoiceRoomBatchGiftModel: NSObject {
  /// 发送者账号
  public var sendAccout: String = ""
  /// 礼物编号
  public var giftId: Int = 0
  /// 礼物个数
  public var giftCount: Int = 0

  public var rewarderUserUuid: String = ""
//  // 打赏者昵称
  public var rewarderUserName: String = ""
  public var rewardeeUserUuid: String = ""
  // 被打赏者昵称
  public var rewardeeUserName: String = ""

  public var seatUserReward: [NEVoiceRoomBatchSeatUserReward]

  internal init(_ rewardMsg: _NEVoiceRoomBatchRewardMessage) {
    sendAccout = rewardMsg.senderUserUuid ?? ""
    giftId = rewardMsg.giftId ?? 0
    giftCount = rewardMsg.giftCount ?? 0
    rewarderUserName = rewardMsg.rewarderUserName ?? ""
    rewarderUserUuid = rewardMsg.rewarderUserUuid ?? ""
    rewardeeUserName = rewardMsg.rewardeeUserName ?? ""
    rewardeeUserUuid = rewardMsg.rewardeeUserUuid ?? ""
    seatUserReward = rewardMsg.seatUserReward.map { NEVoiceRoomBatchSeatUserReward($0) }
  }
}

@objcMembers
public class NEVoiceRoomBatchSeatUserReward: NSObject {
  public var seatIndex: Int = 0
  public var userUuid: String?
  public var userName: String?
  public var rewardTotal: Int = 0
  public var icon: String?

  internal init(_ batchSeatUserReward: _NEVoiceRoomBatchSeatUserReward?) {
    if let batchSeatUserReward = batchSeatUserReward {
      seatIndex = batchSeatUserReward.seatIndex
      userUuid = batchSeatUserReward.userUuid
      userName = batchSeatUserReward.userName
      rewardTotal = batchSeatUserReward.rewardTotal
      icon = batchSeatUserReward.icon
    }
  }
}
