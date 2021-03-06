# frozen_string_literal: true

class MuteService < BaseService
  def call(account, target_account, notifications: nil, duration: 0)
    return if account.id == target_account.id

    mute = account.mute!(target_account, notifications: notifications, duration: duration)

    if mute.hide_notifications?
      BlockWorker.perform_async(account.id, target_account.id)
    else
      MuteWorker.perform_async(account.id, target_account.id)
    end

    if duration != 0
      jid = DeleteMuteWorker.perform_at(duration.seconds, account.id, target_account.id)
      mute.update!(unmute_jid: jid)
    end

    mute
  end
end
