class FishSocket
  # Sorting new message module
  module Listener
    attr_accessor :message, :bot

    def catch_new_message(message,bot)
      self.message = message
      self.bot = bot
      #bot.logger.info(message)
      begin
      #return false if Security.message_too_far
      #bot.logger.info(self.message)
      #p "..................................."
      #p message
      #p "CAPTION======#{message.message_id}"
      #p "================"
      #p Bot_Globals::Uncompressed_Links
      #p Bot_Globals::Uncompressed_Links
      #p "..................................."
      case self.message
      when Telegram::Bot::Types::ChatMemberUpdated
        bot.logger.info(message)
        return
      when Telegram::Bot::Types::CallbackQuery
        CallbackMessages.process(message)
      when Telegram::Bot::Types::Message
        Threads.upload_to_comments(message,bot) if Bot_Globals::Uncompressed_Links!=[]
        StandartMessages.process(message)
      when Telegram::Bot::Types::InlineQuery
        InlineQuery.process(message)
      else
        bot.logger.info("something different")
        bot.logger.info(message)
      end
      rescue Exception => e
        if e.to_s.include? "retry after" or e.to_s.include? "Bad Request"
          Listener::Response.std_message("#{e}",TelegramConstants::ERROR_CHANNEL_ID)
          retry
        end
        if not e.to_s.include? "bot was blocked by the user"
          bot.logger.error(self.message)
          bot.logger.error("#{e}\n#{e.backtrace}")
          #File.write("#{Time.now.to_i}.txt", "#{self.message}\n#{Time.now}\n #{e}\n#{e.backtrace}")#Listener::Response.std_message("#{e}",TelegramConstants::ERROR_CHANNEL_ID)#Listener::Response.std_message("#{e}",TelegramConstants::ERROR_CHANNEL_ID)
          Listener.bot.api.send_message(chat_id:TelegramConstants::ERROR_CHANNEL_ID, text:"Я КРАШНУЛСЯ, но retry")
          Listener.bot.api.send_message(chat_id:TelegramConstants::ERROR_CHANNEL_ID, text:"#{e.to_s[0..4000]}")
        end
        retry
      end
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
