require 'telegram/bot'
require './library/mac-shake.rb'
require './library/texts.rb'
require './modules/listener.rb'
require './modules/security.rb'
require './modules/standart_messages.rb'
require './modules/response.rb'
require './modules/callback_messages.rb'
require './modules/codes.rb'
require './modules/threads.rb'
require './modules/inline_query.rb'
require './modules/logger_overrite.rb'
require 'open-uri'
require "net/http"
require 'json'
# Entry point class
class FishSocket
  def initialize
    super
    puts "RUNNING"
    TelegramConstants.setup
    logger_overrite()
    p TelegramConstants::WHITE_LIST_IDS
    Telegram::Bot::Client.run(TelegramConstants::API_KEY, logger: Logger.new("log.log",3, 10 * 1024 * 1024), url:'http://127.0.0.1:8081') do |bot|
      # Start time variable, for exclude message what was sends before bot starts
      bot.logger.info('Bot has been started')
      bot.api.send_message(chat_id: TelegramConstants::ERROR_CHANNEL_ID, text: "RUNNING")
      # Active socket listener
      Threads.startup(bot)
    end
  end
end
# Bot start
FishSocket.new
