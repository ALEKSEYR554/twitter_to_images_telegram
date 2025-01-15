require 'telegram/bot'
require './library/mac-shake'
require './library/texts'
require './modules/listener'
require './modules/security'
require './modules/standart_messages'
require './modules/response'
require './modules/callback_messages'
require './modules/codes'
require './modules/threads'
require './modules/inline_query'
require './modules/logger_overrite'
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
    Telegram::Bot::Client.run(TelegramConstants::API_KEY, logger: Logger.new("log.log",3, 10 * 1024 * 1024)) do |bot|
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
