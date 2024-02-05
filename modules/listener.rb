class FishSocket
  # Sorting new message module
  module Listener
    attr_accessor :message, :bot

    def catch_new_message(message,bot)
      self.message = message
      self.bot = bot
      #begin
      #return false if Security.message_too_far
      case self.message
      when Telegram::Bot::Types::CallbackQuery
        CallbackMessages.process
      when Telegram::Bot::Types::Message
        StandartMessages.process
      end
      #rescue Exception => e
      #  Listener::Response.std_message("#{e}",TelegramConstants::ERROR_CHANNEL_ID)
      #  retry
      #  if e.to_s.include? "retry after"
      #    Listener::Response.std_message("#{e}",TelegramConstants::ERROR_CHANNEL_ID)
      #    retry
      #  end
      #  if not e.to_s.include? "bot was blocked by the user"
      #    Listener.bot.api.send_message(chat_id:TelegramConstants::ERROR_CHANNEL_ID, text:"Я КРАШНУЛСЯ")
      #  end
      #end
    end

    module_function(
      :catch_new_message,
      :message,
      :message=,
      :bot,
      :bot=
    )
  end
end
