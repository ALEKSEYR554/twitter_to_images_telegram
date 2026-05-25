at_exit do
  # Принудительно освобождаем заблокированные файлы перед выходом из программы (при Ctrl+C)
  if defined?(Bot_Globals::Uncompressed_Links) && Bot_Globals::Uncompressed_Links
    Bot_Globals::Uncompressed_Links.each do |link_item|
      next unless link_item.is_a?(Hash)
      
      # Закрываем файловые потоки Faraday
      if link_item[:out_document]
        link_item[:out_document].flatten.each do |doc|
          if doc.is_a?(Hash) && doc[:io]
            doc[:io].close rescue nil
          end
        end
      end
      
      # Удаляем временные файлы
      if link_item[:temp_files]
        link_item[:temp_files].each do |tf|
          tf.close rescue nil
          tf.unlink rescue nil
        end
      end
    end
  end
end


class FishSocket
  module Threads
    def upload_to_comments(message,bot)
      #p message
      if message.forward_origin
        #p "ORIGINAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        #p "CAPTION======#{message.caption}"
        #p message
        if Bot_Globals::Uncompressed_Links==[]
          return
        else #sending uncompressed in comments
          for i in 0..Bot_Globals::Uncompressed_Links.length-1
            #p message.forward_origin.chat.id 
            next if Bot_Globals::Uncompressed_Links[i]==nil
            break if !message.forward_origin.is_a?(Telegram::Bot::Types::MessageOriginChannel)

            if Time.at((Time.now.to_i-Bot_Globals::Uncompressed_Links[i][:unix_date]).abs).min>=2
              expired_item = Bot_Globals::Uncompressed_Links[i]
              if expired_item[:out_document]
                expired_item[:out_document].flatten.each do |item|
                  item[:io].close if item[:io] && !item[:io].closed?
                end
              end
              if expired_item[:temp_files]
                expired_item[:temp_files].each { |tf| tf.unlink rescue nil }
              end
              Bot_Globals::Uncompressed_Links.delete(Bot_Globals::Uncompressed_Links[i])
              next
            end
            
            bot.logger.info("Проверяем на наличие нужной ссылки Сообщение в чате:#{message.chat.id} переслано из:#{message.forward_origin.chat.id}")
            #return if Bot_Globals::Uncompressed_Links==[]
            #p Bot_Globals::Uncompressed_Links
            #p Bot_Globals::Uncompressed_Links[i]
            #p Bot_Globals::Uncompressed_Links[i][:chat__id]
            #p message.caption_entities
            bot.logger.info(Bot_Globals::Uncompressed_Links)
            next if Bot_Globals::Uncompressed_Links==[]
            next if Bot_Globals::Uncompressed_Links[i]==nil
            if message.forward_origin.chat.id==Bot_Globals::Uncompressed_Links[i][:chat__id]
              return if message.caption_entities==nil
              #p message
              for entitie in message.caption_entities
                #p "#{entitie.url}____#{Bot_Globals::Uncompressed_Links[i][:source_lnk]}"
                #p entitie
                return if Bot_Globals::Uncompressed_Links[i].nil?
                if entitie.url==Bot_Globals::Uncompressed_Links[i][:source_lnk]
                  out_doc=Bot_Globals::Uncompressed_Links[i][:out_document]
                  stored_temp_files=Bot_Globals::Uncompressed_Links[i][:temp_files] # Получаем временные файлы
                  Bot_Globals::Uncompressed_Links.delete(Bot_Globals::Uncompressed_Links[i])
                  
                  begin
                    sleep(2*out_doc.length)
                    for slice in out_doc
                      # Базовый запрос с привязкой к комментарию
                      request_sample = {
                        chat_id: message.chat.id,
                        media: [],
                        reply_parameters: Telegram::Bot::Types::ReplyParameters.new(message_id: message.message_id)
                      }
                      
                      media_request_media = []
                      media_request_files = []
                      
                      # Собираем файлы в запрос
                      slice.each_with_index do |item, idx|
                        if item[:downloaded]
                          attach_name = "file#{idx}"
                          media_request_media << Telegram::Bot::Types::InputMediaDocument.new(media: "attach://#{attach_name}")
                          # Оборачиваем UploadIO в FilePart (магия из Pixiv кода)
                          media_request_files << Hash[:"#{attach_name}", Faraday::FilePart.new(item[:io], item[:exten])]
                        else
                          # Запасной вариант - отправка по ссылке, если скачивание было отключено или не удалось
                          media_request_media << Telegram::Bot::Types::InputMediaDocument.new(media: item[:url])
                        end
                      end
                      
                      temp = request_sample.dup
                      # Вшиваем сами файлы в корень запроса
                      if media_request_files.any?
                        temp = request_sample.merge(media_request_files.inject(&:merge))
                      end
                      temp[:media] = media_request_media
                      
                      bot.api.send_media_group(temp)
                      sleep(5)
                    end
                  rescue Exception=> e
                    p e
                    #p e.backtrace
                    case e.to_s
                    when /Internal Server Error/
                      bot.logger.info(e)
                      sleep(1)
                      bot.logger.info(e)
                      retry
                    when /Too Many Requests: retry after/
                        ttt=e.to_s[e.to_s.index('parameters: {"retry_after"=>')+28..e.to_s.index('})')-1]
                        bot.logger.warn(e)
                        sleep(ttt.to_i)
                        retry
                    end
                    Listener.bot.logger.info(message)
                    File.write("#{Time.now.to_i}.txt", "#{Time.now}\n #{e}\n#{e.backtrace}")
                    return
                  
                  ensure
                    # ОБЯЗАТЕЛЬНО: После отправки (или ошибки) закрываем файловые дескрипторы и удаляем файлы на Windows
                    if out_doc
                      out_doc.flatten.each do |item|
                        item[:io].close if item[:io] && !item[:io].closed?
                      end
                    end
                    if stored_temp_files
                      stored_temp_files.each { |tf| tf.unlink rescue nil }
                    end
                  end
                  bot.logger.info("something was sent to comments")
                end
              end
            end
          end
        end
      end
    end
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
      begin
      bot.listen do |message|
        # Processing the new income message    #if that message sent after bot run.
        Thread.new{Listener.catch_new_message(message,bot)}# if Listener::Security.message_is_new(start_bot_time,message) #disables BC OF INLINE MODE ENABLED
      end
      rescue Exception => e
        sleep(1)
        p "Errr"
        bot.logger.error(e)
        bot.logger.error(e.backtrace)
        retry
        #  Listener::Response.std_message("ERRRRRRRRRRRRRRROR",TelegramConstants::ERROR_CHANNEL_ID)
        #  Listener::Response.std_message("#{e}",TelegramConstants::ERROR_CHANNEL_ID)
      end
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
      :update_info,
      :upload_to_comments
    )
  end
end
