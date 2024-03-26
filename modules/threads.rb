class FishSocket
  module Threads
    def update_info(bot,main_bot,this_thread)
      while true
        if main_bot.alive?
          #bot.api.send_message(chat_id:TelegramConstants::ERROR_CHANNEL_ID, text: "still_run",disable_notification:true)
          sleep(1800)
        else
          bot.api.send_message(chat_id:TelegramConstants::ERROR_CHANNEL_ID, text: "I AM NOT RUNNING")
          this_thread.exit
          break
        end
      end
    end
    def main_bot(bot,start_bot_time)
      #begin
      bot.listen do |message|
        # Processing the new income message    #if that message sent after bot run.
        Thread.new{Listener.catch_new_message(message,bot)}# if Listener::Security.message_is_new(start_bot_time,message) #disables BC OF INLINE MODE ENABLED
      end
      #rescue Exception => e
      #  if e.to_s.include?"retry_after"
      #    p e
      #    sleep(5.3)
      #    retry
      #  end
      #  Listener::Response.std_message("ERRRRRRRRRRRRRRROR",TelegramConstants::ERROR_CHANNEL_ID)
      #  Listener::Response.std_message("#{e}",TelegramConstants::ERROR_CHANNEL_ID)
      #end
    end
    def startup(bot)
      start_bot_time = Time.now.to_i
      main_bot_thread = Thread.new{Threads.main_bot(bot,start_bot_time)}
      update_status_thread = Thread.new{Threads.update_info(bot,main_bot_thread,update_status_thread)}

      main_bot_thread.join
      update_status_thread.join
    end
    module_function(
      :startup,
      :main_bot,
      :update_info
    )
  end
end
