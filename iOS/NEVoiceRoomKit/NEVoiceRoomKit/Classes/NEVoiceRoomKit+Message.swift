// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NERoomKit

public extension NEVoiceRoomKit {
  /// 发送聊天室消息
  ///
  /// 使用前提：该方法仅在调用[login]方法登录成功后调用有效
  /// - Parameters:
  ///   - content: 发送内容
  ///   - callback: 回调
  func sendTextMessage(_ content: String, callback: NEVoiceRoomCallback<AnyObject>? = nil) {
    NEVoiceRoomLog.apiLog(kitTag, desc: "Send text message. Content: \(content).")
    Judge.preCondition({
      self.roomContext!.chatController
        .sendBroadcastTextMessage(message: content) { code, msg, _ in
          if code == 0 {
            NEVoiceRoomLog.successLog(kitTag, desc: "Successfully send text messge.")
          } else {
            NEVoiceRoomLog.errorLog(
              kitTag,
              desc: "Failed to send text messge. Code: \(code). Msg: \(msg ?? "")"
            )
          }
          callback?(code, msg, nil)
        }
    }, failure: callback)
  }

  /// 给房间内用户发送自定义消息，如房间内信令
  /// - Parameters:
  ///   - userUuid: 目标成员Id
  ///   - commandId: 消息类型 区间[10000 - 19999]
  ///   - data: 自定义消息内容
  ///   - callback: 回调
  func sendCustomMessage(_ userUuid: String,
                         commandId: Int,
                         data: String,
                         callback: NEVoiceRoomCallback<AnyObject>? = nil) {
    NEVoiceRoomLog.apiLog(
      kitTag,
      desc: "Send custom message. UserUuid: \(userUuid). CommandId: \(commandId). Data: \(data)"
    )
    Judge.preCondition({
      NERoomKit.shared().messageChannelService
        .sendCustomMessage(roomUuid: self.roomContext!.roomUuid,
                           userUuid: userUuid,
                           commandId: commandId,
                           data: data) { code, msg, _ in
          if code == 0 {
            NEVoiceRoomLog.successLog(kitTag, desc: "Successfully send custom message.")
          } else {
            NEVoiceRoomLog.errorLog(
              kitTag,
              desc: "Failed to send custom message. Code: \(code). Msg: \(msg ?? "")"
            )
          }
          callback?(code, msg, nil)
        }
    }, failure: callback)
  }

  /// 处理RoomKit自定义消息
  func handleCustomMessage(_ message: NERoomChatCustomMessage) {
    NEVoiceRoomLog.infoLog(kitTag, desc: "Receive custom message.")
    guard let dic = message.attachStr?.toDictionary() else { return }
    NEVoiceRoomLog.infoLog(kitTag, desc: "custom message:\(dic)")
    if let data = dic["data"] as? [String: Any],
       let cmd = data["cmd"] as? Int {
    } else if let content = message.attachStr,
              let subCmd = dic["subCmd"] as? Int,
              let type = dic["type"] as? Int,
              subCmd == 2,
              type == 1001,
              let obj = NEVoiceRoomDecoder.decode(
                _NEVoiceRoomRewardMessage.self,
                jsonString: content
              ) {
      handleGiftMessage(obj)
    } else if let content = message.attachStr,
              let subCmd = dic["subCmd"] as? Int,
              let type = dic["type"] as? Int,
              subCmd == 4,
              type == 1002,
              let obj = NEVoiceRoomDecoder.decode(
                _NEVoiceRoomBatchRewardMessage.self,
                jsonString: content
              ) {
      handleBatchGiftMessage(obj)
    }
  }

  /// 发送礼物
  /// - Parameters:
  ///   - giftId: 礼物Id
  func sendGift(_ giftId: Int,
                callback: NEVoiceRoomCallback<AnyObject>? = nil) {
    NEVoiceRoomLog.apiLog(kitTag, desc: "Send gift. GiftId: \(giftId)")
    guard NEVoiceRoomKit.getInstance().isInitialized else {
      NEVoiceRoomLog.errorLog(kitTag, desc: "Failed to send Gift. Uninitialized.")
      callback?(NEVoiceRoomErrorCode.failed, "Failed to send Gift. Uninitialized.", nil)
      return
    }
    guard let liveRecordId = liveInfo?.live?.liveRecordId
    else {
      NEVoiceRoomLog.errorLog(kitTag, desc: "Failed to send Gift. liveRecordId not exist.")
      callback?(
        NEVoiceRoomErrorCode.failed,
        "Failed to send Gift. liveRecordId not exist.",
        nil
      )
      return
    }
    roomService.reward(liveRecordId, giftId: giftId) {
      callback?(NEVoiceRoomErrorCode.success, "Successfully send gift.", nil)
    } failure: { error in
      callback?(error.code, error.localizedDescription, nil)
    }
  }

  func sendBatchGift(_ giftId: Int,
                     giftCount: Int,
                     userUuids: [String],
                     callback: NEVoiceRoomCallback<AnyObject>? = nil) {
    guard NEVoiceRoomKit.getInstance().isInitialized else {
      NEVoiceRoomLog.errorLog(kitTag, desc: "Failed to send batch gift. Uninitialized.")
      callback?(NEVoiceRoomErrorCode.failed, "Failed to send batch gift. Uninitialized.", nil)
      return
    }
    guard let liveRecordId = liveInfo?.live?.liveRecordId
    else {
      NEVoiceRoomLog.errorLog(kitTag, desc: "Failed to send batch gift. liveRecordId not exist.")
      callback?(
        NEVoiceRoomErrorCode.failed,
        "Failed to send batch gift. liveRecordId not exist.",
        nil
      )
      return
    }
    roomService.batchReward(liveRecordId, giftId: giftId, giftCount: giftCount, userUuids: userUuids) {
      callback?(NEVoiceRoomErrorCode.success, "Successfully send batch gift.", nil)
    } failure: { error in
      callback?(error.code, error.localizedDescription, nil)
    }
  }

  /// 处理礼物消息
  internal func handleGiftMessage(_ rewardMsg: _NEVoiceRoomRewardMessage) {
    guard let _ = rewardMsg.rewarderUserUuid,
          let _ = rewardMsg.rewarderUserName,
          let _ = rewardMsg.giftId
    else { return }
    let giftModel = NEVoiceRoomGiftModel(rewardMsg)
    NEVoiceRoomLog.messageLog(
      kitTag,
      desc: "Handle gift message. SendAccount: \(giftModel.sendAccout). SendNick: \(giftModel.sendNick). GiftId: \(giftModel.giftId)"
    )
    DispatchQueue.main.async {
      for pointerListener in self.listeners.allObjects {
        guard pointerListener is NEVoiceRoomListener, let listener = pointerListener as? NEVoiceRoomListener else { continue }

        if listener.responds(to: #selector(NEVoiceRoomListener.onReceiveGift(giftModel:))) {
          listener.onReceiveGift?(giftModel: giftModel)
        }
      }
    }
  }

  /// 处理批量礼物消息
  internal func handleBatchGiftMessage(_ rewardMsg: _NEVoiceRoomBatchRewardMessage) {
    guard let _ = rewardMsg.rewarderUserUuid,
          let _ = rewardMsg.rewarderUserName,
          let _ = rewardMsg.rewardeeUserName,
          let _ = rewardMsg.giftId
    else { return }
    let giftModel = NEVoiceRoomBatchGiftModel(rewardMsg)
    NEVoiceRoomLog.messageLog(
      kitTag,
      desc: "Handle batch gift message. SendAccount: \(giftModel.rewarderUserUuid). SendNick: \(giftModel.rewarderUserName). GiftId: \(giftModel.giftId). rewarderUserUuid:\(giftModel.rewarderUserUuid) rewarderUserName:\(giftModel.rewardeeUserName)"
    )
    DispatchQueue.main.async {
      for pointerListener in self.listeners.allObjects {
        guard pointerListener is NEVoiceRoomListener, let listener = pointerListener as? NEVoiceRoomListener else { continue }

        if listener.responds(to: #selector(NEVoiceRoomListener.onReceiveBatchGift(giftModel:))) {
          listener.onReceiveBatchGift?(giftModel: giftModel)
        }
      }
    }
  }
}

extension NEVoiceRoomKit: NERoomListener {
  public func onRtcAudioVolumeIndication(volumes: [NEMemberVolumeInfo],
                                         totalVolume: Int) {
    DispatchQueue.main.async {
      for pointerListener in self.listeners.allObjects {
        guard pointerListener is NEVoiceRoomListener, let listener = pointerListener as? NEVoiceRoomListener else { continue }
        if listener.responds(to: #selector(NEVoiceRoomListener.onRtcAudioVolumeIndication(volumes:totalVolume:))) {
          let v: [NEVoiceRoomMemberVolumeInfo] = volumes.map { info in
            NEVoiceRoomMemberVolumeInfo(info: info)
          }
          listener.onRtcAudioVolumeIndication?(volumes: v, totalVolume: totalVolume)
        }
      }
    }
  }

  public func onRtcAudioEffectFinished(effectId: UInt32) {
    DispatchQueue.main.async {
      for pointerListener in self.listeners.allObjects {
        guard pointerListener is NEVoiceRoomListener, let listener = pointerListener as? NEVoiceRoomListener else { continue }
        if listener.responds(to: #selector(NEVoiceRoomListener.onAudioEffectFinished)) {
          listener.onAudioEffectFinished?()
        }
      }
    }
  }

  public func onRtcAudioEffectTimestampUpdate(effectId: UInt32, timeStampMS: UInt64) {
    DispatchQueue.main.async {
      for pointerListener in self.listeners.allObjects {
        guard pointerListener is NEVoiceRoomListener, let listener = pointerListener as? NEVoiceRoomListener else { continue }
        if listener
          .responds(to: #selector(NEVoiceRoomListener.onAudioEffectTimestampUpdate(_:timeStampMS:))) {
          listener.onAudioEffectTimestampUpdate?(effectId, timeStampMS: timeStampMS)
        }
      }
    }
  }

  public func onMemberPropertiesChanged(member: NERoomMember, properties: [String: String]) {
    DispatchQueue.main.async {
      if properties.keys.contains(MemberPropertyConstants.MuteAudio.key) { // mute audio
        for pointListener in self.listeners.allObjects {
          guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

          let mem = NEVoiceRoomMember(member)
          if listener
            .responds(to: #selector(NEVoiceRoomListener
                .onMemberAudioMuteChanged(_:mute:operateBy:))) {
            listener.onMemberAudioMuteChanged?(mem, mute: !mem.isAudioOn, operateBy: nil)
          }
        }
      } else if properties.keys.contains(MemberPropertyConstants.CanOpenMic.key) { // ban
        let ban: Bool = properties[MemberPropertyConstants.CanOpenMic.key] ==
          MemberPropertyConstants.CanOpenMic.no
        let mem = NEVoiceRoomMember(member)
        for pointListener in self.listeners.allObjects {
          guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

          if listener
            .responds(to: #selector(NEVoiceRoomListener.onMemberAudioBanned(_:banned:))) {
            listener.onMemberAudioBanned?(mem, banned: ban)
          }
        }
      }
    }
  }

  public func onMemberJoinRtcChannel(members: [NERoomMember]) {
    for member in members {
      if member.uuid == localMember?.account {
        roomContext?.rtcController.unmuteMyAudio()
      }
    }
  }

  public func onMemberJoinRoom(members: [NERoomMember]) {
    DispatchQueue.main.async {
      let list = members.map { NEVoiceRoomMember($0) }
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener.responds(to: #selector(NEVoiceRoomListener.onMemberJoinRoom(_:))) {
          listener.onMemberJoinRoom?(list)
        }
      }
    }
  }

  public func onMemberLeaveRoom(members: [NERoomMember]) {
    DispatchQueue.main.async {
      let list = members.map { NEVoiceRoomMember($0) }
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener.responds(to: #selector(NEVoiceRoomListener.onMemberLeaveRoom(_:))) {
          listener.onMemberLeaveRoom?(list)
        }
      }
    }
  }

  public func onMemberJoinChatroom(members: [NERoomMember]) {
    DispatchQueue.main.async {
      let list = members.map { NEVoiceRoomMember($0) }
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener.responds(to: #selector(NEVoiceRoomListener.onMemberJoinChatroom(_:))) {
          listener.onMemberJoinChatroom?(list)
        }
      }
    }
  }

  public func onRoomEnded(reason: NERoomEndReason) {
    DispatchQueue.main.async {
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener.responds(to: #selector(NEVoiceRoomListener.onRoomEnded(_:))) {
          listener
            .onRoomEnded?(NEVoiceRoomEndReason(rawValue: reason.rawValue) ?? .unknow)
        }
      }
    }
  }

  public func onRtcChannelError(code: Int) {
    DispatchQueue.main.async {
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener.responds(to: #selector(NEVoiceRoomListener.onRtcChannelError(_:))) {
          listener.onRtcChannelError?(code)
        }
      }
    }
  }

  public func onReceiveChatroomMessages(messages: [NERoomChatMessage]) {
    DispatchQueue.main.async {
      for message in messages {
        switch message.messageType {
        case .text:
          for pointListener in self.listeners.allObjects {
            guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener,
                  let textMessage = message as? NERoomChatTextMessage else { continue }

            if listener
              .responds(to: #selector(NEVoiceRoomListener.onReceiveTextMessage(_:))) {
              listener
                .onReceiveTextMessage?(
                  NEVoiceRoomChatTextMessage(textMessage)
                )
            }
          }
        case .custom:
          if let msg = message as? NERoomChatCustomMessage {
            self.handleCustomMessage(msg)
          }

        case .image: break
        case .file: break
        @unknown default: break
        }
      }
    }
  }

  public func onSeatRequestSubmitted(_ seatIndex: Int, user: String) {
    DispatchQueue.main.async {
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener
          .responds(to: #selector(NEVoiceRoomListener.onSeatRequestSubmitted(_:account:))) {
          listener.onSeatRequestSubmitted?(seatIndex, account: user)
        }
      }
    }
  }

  public func onSeatRequestCancelled(_ seatIndex: Int, user: String) {
    DispatchQueue.main.async {
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener
          .responds(to: #selector(NEVoiceRoomListener.onSeatRequestCancelled(_:account:))) {
          listener.onSeatRequestCancelled?(seatIndex, account: user)
        }
      }
    }
  }

  public func onSeatRequestApproved(_ seatIndex: Int, user: String, operateBy: String,
                                    isAutoAgree: Bool) {
    DispatchQueue.main.async {
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener
          .responds(to: #selector(NEVoiceRoomListener
              .onSeatRequestApproved(_:account:operateBy:isAutoAgree:))) {
          listener.onSeatRequestApproved?(
            seatIndex,
            account: user,
            operateBy: operateBy,
            isAutoAgree: isAutoAgree
          )
        }
      }
    }
  }

  public func onSeatRequestRejected(_ seatIndex: Int, user: String, operateBy: String) {
    DispatchQueue.main.async {
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener
          .responds(to: #selector(NEVoiceRoomListener
              .onSeatRequestRejected(_:account:operateBy:))) {
          listener.onSeatRequestRejected?(seatIndex, account: user, operateBy: operateBy)
        }
      }
    }
  }

  public func onSeatLeave(_ seatIndex: Int, user: String) {
    DispatchQueue.main.async {
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener.responds(to: #selector(NEVoiceRoomListener.onSeatLeave(_:account:))) {
          listener.onSeatLeave?(seatIndex, account: user)
        }
      }
    }
  }

  public func onSeatKicked(_ seatIndex: Int, user: String, operateBy: String) {
    DispatchQueue.main.async {
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener
          .responds(to: #selector(NEVoiceRoomListener.onSeatKicked(_:account:operateBy:))) {
          listener.onSeatKicked?(seatIndex, account: user, operateBy: operateBy)
        }
      }
    }
  }

  /// seat open
  /// seat close
  /// seat enter

  public func onSeatListChanged(_ seatItems: [NESeatItem]) {
    DispatchQueue.main.async {
      let items = seatItems.map { NEVoiceRoomSeatItem($0) }
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener.responds(to: #selector(NEVoiceRoomListener.onSeatListChanged(_:))) {
          listener.onSeatListChanged?(items)
        }
      }
      guard let context = self.roomContext else { return }
      var isOnSeat = false
      for item in items {
        if item.user == context.localMember.uuid,
           item.status == .taken {
          isOnSeat = true
        }
      }
      // 不在麦位，且属性 被ban, 删除属性
      if !isOnSeat, context.localMember.properties[MemberPropertyConstants.CanOpenMic.key] ==
        MemberPropertyConstants.CanOpenMic.no {
        context.deleteMemberProperty(
          userUuid: context.localMember.uuid,
          key: MemberPropertyConstants.CanOpenMic.key
        )
      }
      context.rtcController.setClientRole(isOnSeat ? .broadcaster : .audience)
    }
  }

  public func onSeatInvitationAccepted(_ seatIndex: Int, user: String, isAutoAgree: Bool) {
    DispatchQueue.main.async {
      for pointListener in self.listeners.allObjects {
        guard pointListener is NEVoiceRoomListener, let listener = pointListener as? NEVoiceRoomListener else { continue }

        if listener
          .responds(to: #selector(NEVoiceRoomListener
              .onSeatInvitationAccepted(_:account:isAutoAgree:))) {
          listener.onSeatInvitationAccepted?(
            seatIndex,
            account: user,
            isAutoAgree: isAutoAgree
          )
        }
      }
    }
  }
}
