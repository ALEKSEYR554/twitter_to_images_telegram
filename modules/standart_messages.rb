class FishSocket
  module Listener
    # This module assigned to processing all standart messages
    module StandartMessages
      def transform_string(input_string)
        transformed_string = input_string.gsub(/#[^ !@#$%^&*(),.?":{}|<>]*/,'')#(/#\.*.+\s|$/, '')
        transformed_string.gsub!(/\n+$/, '')
        transformed_string.gsub!("&","&amp")
        transformed_string.gsub!("<",'&lt')
        transformed_string.gsub!(">","&gt")
        transformed_string.strip
      end
      def clean_html(html_text)
        return "" if html_text.nil?
        cleaned = html_text.dup
        cleaned.gsub!(/<br\s*\/?>/i, "\n")
        cleaned.gsub!(/<\/p>\s*<p[^>]*>/i, "\n\n")
        cleaned.gsub!(/<[^>]+>/, "")
        cleaned = CGI.unescapeHTML(cleaned)
        cleaned.strip
      end
      def response_to_images(message,response,host_url="twitter")
        #p "----------------"
        download_images = TelegramConstants::DOWNLOAD_IMAGES
        out=[]
        chat__id = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
        author_hashtag=[]
        source_lnk=[]
        quote=[]
        out_compressed=[];out_document=[]
        temp_files = []
        out_compressed_items = []
        out_document_items = []
        case host_url
        when "twitter"
          if response[0].is_a? String
            return
          end
          p response
          if !response.is_a? (Array)
            response=[response]
          end
          p "1"
          #p response
          first_link=response[0]["tweet"]["url"]
          count=0
          for individual_response in response #adding caption
            author_hashtag<<"##{individual_response["tweet"]["author"]["screen_name"]}"
  
            source_lnk<<"<a href=\"#{individual_response["tweet"]["url"]}\">Source twitter#{(count!=0)? " "+(count+1).to_s : ""}</a>"#""+message.text        
  
            quote<<"<blockquote>#{StandartMessages.transform_string(individual_response["tweet"]["text"])}</blockquote>"
            count+=1
            p "2"
          end
          
          #out=out.each_slice(10).to_a
          
          
          p "FUUUUUUUUUUUU"
          #p quote
          #p author_hashtag
          #p source_lnk
          if quote.length>=2
            quote=[""]
          end
          for i in 0..response.length-1 do #getting all media links
            #debug comments ----------------
            #File.open("#{out[i][out[i].index('/media/')+7..]}", 'wb') { |fp| fp.write(response.body) }
            #IO.copy_stream(URI.open("#{out[i]}:orig"), "./test_files/#{out[i][out[i].index('/media/')+7..]}")
            #p response ------------------
            for j in 0..response[i]['tweet']["media"]['all'].length-1 do
              media=response[i]['tweet']["media"]['all'][j]
              if i==0 and j==0
                capt= "#{quote.join("\n")}\n#{author_hashtag.uniq.join(" ")}\n#{source_lnk.join("\n")}"
              else
                capt=""
              end

              url_to_use = media["url"]
              p "url_to_use = #{url_to_use}"

              case media["type"]
              when "video"
                video_to_upload=media
                if media.has_key? "variants"
                  url_to_use = media["variants"][-1]["url"]
                  (media["variants"].length-1).downto(1).each { |id|
                      video_url=media["variants"][id]["url"]
                      next if video_url.include?(".m3u8")
                      size_in_bytes = InlineQuery.get_file_size_from_url(video_url)

                      if size_in_bytes
                          size_in_mb = size_in_bytes / (1024.0 * 1024.0)
                      else
                          size_in_mb=99
                      end
                      p ""
                      if (size_in_mb<=21)
                          video_to_upload=media["variants"][id]
                          break
                      end
                  }
                end
              when "gif"
                url_to_use = individual_response["tweet"]["media"]["all"][j]["url"]
              end
              item_downloaded = false
              media_source_compressed = url_to_use
              media_source_document = url_to_use
              
              file_io_comp = nil
              file_io_doc = nil
              exten = "image/jpeg"

              url_thumb_to_use = (media["type"] == "video") ? media["thumbnail_url"] : nil

              if download_images && media["type"] != "gif"
                begin
                  ext = url_to_use.split('.').last.split('?').first
                  ext = 'jpg' if ext.to_s.empty? || ext.length > 4
                  exten = (ext == 'mp4') ? 'video/mp4' : 'image/jpeg'
                  exten = 'image/png' if ext == 'png'
                  
                  tf = Tempfile.new(['twit_media', ".#{ext}"])
                  tf.binmode
                  URI.open(url_to_use) { |io| tf.write(io.read) }
                  tf.close
                  temp_files << tf
                  
                  # Используем Faraday::UploadIO точно как в твоем рабочем коде
                  file_io_comp = Faraday::UploadIO.new(tf.path, exten)
                  file_io_doc  = Faraday::UploadIO.new(tf.path, exten) if media["type"] == "photo"
                  item_downloaded = true

                  if media["type"] == "video" && url_thumb_to_use
                    ext_thumb = url_thumb_to_use.split('.').last.split('?').first
                    ext_thumb = 'jpg' if ext_thumb.to_s.empty? || ext_thumb.length > 4
                    
                    tf_thumb = Tempfile.new(['twit_thumb', ".#{ext_thumb}"])
                    tf_thumb.binmode
                    URI.open(url_thumb_to_use) { |io| tf_thumb.write(io.read) }
                    tf_thumb.close
                    temp_files << tf_thumb
                    
                    file_io_thumb = Faraday::UploadIO.new(tf_thumb.path, 'image/jpeg')
                    thumb_downloaded = true
                  end
                rescue => e
                  Listener.bot.logger.error("Download failed: #{e}")
                  item_downloaded = false
                end
              end


              p "media_source_compressed = #{media_source_compressed}"
              request_sample={
                chat_id: message.chat.id,
                media: []
              }
              case media["type"]
              when "video"
                out_compressed_items << { 
                  type: "video",
                  downloaded: item_downloaded, 
                  url: url_to_use, 
                  io: file_io_comp, 
                  duration: media["duration"], width: media["width"], height: media["height"], 
                  exten: "video/mp4", 
                  thumb_downloaded: thumb_downloaded,
                  thumb_url: url_thumb_to_use,
                  thumb_io: file_io_thumb,
                  caption: capt 
                }
              when "gif"
                if item_downloaded
                  Listener.bot.api.send_animation(chat_id: chat__id, animation: Faraday::UploadIO.new(temp_files.last.path, exten), caption: capt, parse_mode: "HTML")
                else
                  Listener.bot.api.send_animation(
                    chat_id:chat__id,
                    animation: media_source_compressed,
                    caption:capt,
                    parse_mode:"HTML"
                  )
                end
              when "photo"
                out_compressed_items << { type: "photo", downloaded: item_downloaded, url: url_to_use, io: file_io_comp, exten: exten, caption: capt }
                out_document_items << { type: "document", downloaded: item_downloaded, url: url_to_use, io: file_io_doc, exten: exten }
              end
            end
          end
          out_compressed_slices = out_compressed_items.each_slice(10).to_a
          out_document_slices = out_document_items.each_slice(10).to_a
          
          out_document = out_document_slices
        when "Bluesky"
          if response[0].is_a? String
            return
          end
          if !response.is_a? (Array)
            response=[response]
          end
          first_link=response[0][:post_info]["status"]["url"]
          count=0
          
          for individual_response in response
            # Telegram не поддерживает точки в хештегах, поэтому заменяем их на подчеркивания
            handle = individual_response[:post_info]["status"]["author"]["screen_name"].gsub('.', '_')
            author_hashtag<<"##{handle}"
  
            source_lnk<<"<a href=\"#{individual_response[:post_info]["status"]["url"]}\">Source bluesky#{(count!=0)? " "+(count+1).to_s : ""}</a>"       
  
            cleaned_text = individual_response[:post_info]["status"]["text"] || ""
            quote<<"<blockquote>#{StandartMessages.transform_string(cleaned_text)}</blockquote>"
            count+=1
          end
          
          if quote.length>=2
            quote=[""]
          end
          
          for i in 0..response.length-1 do
            # Забираем медиа из массива all (как у твиттера)
            media_list = response[i][:post_info]["status"]["media"] && response[i][:post_info]["status"]["media"]["all"] ? response[i][:post_info]["status"]["media"]["all"] : []
            
            for j in 0..media_list.length-1 do
              media = media_list[j]
              if i==0 and j==0
                capt= "#{quote.join("\n")}\n#{author_hashtag.uniq.join(" ")}\n#{source_lnk.join("\n")}"
              else
                capt=""
              end
              
              url_to_use = media["url"]
              item_downloaded = false
              file_io_comp = nil
              file_io_doc = nil
              exten = "image/jpeg"

              thumb_downloaded = false
              file_io_thumb = nil
              url_thumb_to_use = (media["type"] == "video") ? media["thumbnail_url"] : nil

              if download_images && media["type"] != "gif" && url_to_use
                begin
                  ext = url_to_use.split('.').last.split('?').first
                  ext = 'jpg' if ext.to_s.empty? || ext.length > 4
                  exten = (ext == 'mp4' || media["type"] == "video") ? 'video/mp4' : 'image/jpeg'
                  exten = 'image/png' if ext == 'png'
                  
                  tf = Tempfile.new(['bluesky_media', ".#{ext}"])
                  tf.binmode
                  URI.open(url_to_use) { |io| tf.write(io.read) }
                  tf.close
                  temp_files << tf
                  
                  file_io_comp = Faraday::UploadIO.new(tf.path, exten)
                  file_io_doc  = Faraday::UploadIO.new(tf.path, exten) if media["type"] == "photo" || media["type"] == "image"
                  item_downloaded = true

                  # Скачивание превью для видео
                  if media["type"] == "video" && url_thumb_to_use
                    ext_thumb = url_thumb_to_use.split('.').last.split('?').first
                    ext_thumb = 'jpg' if ext_thumb.to_s.empty? || ext_thumb.length > 4
                    
                    tf_thumb = Tempfile.new(['bluesky_thumb', ".#{ext_thumb}"])
                    tf_thumb.binmode
                    URI.open(url_thumb_to_use) { |io| tf_thumb.write(io.read) }
                    tf_thumb.close
                    temp_files << tf_thumb
                    
                    file_io_thumb = Faraday::UploadIO.new(tf_thumb.path, 'image/jpeg')
                    thumb_downloaded = true
                  end
                rescue => e
                  Listener.bot.logger.error("Bluesky Download failed: #{e}")
                  item_downloaded = false
                end
              end

              # Иногда API отдает 0, что может сломать таймер Telegram. Если 0 — передаем nil
              dur = media["duration"].to_i
              dur = nil if dur <= 0 
              
              case media["type"]
              when "video"
                out_compressed_items << { 
                  type: "video", 
                  downloaded: item_downloaded, 
                  url: url_to_use, 
                  io: file_io_comp, 
                  exten: exten, 
                  caption: capt,
                  width: 0,#media["width"] && media["width"] > 0 ? media["width"] : nil, 
                  height: 0,#media["height"] && media["height"] > 0 ? media["height"] : nil, 
                  duration: 0,#dur,
                  thumb_downloaded: thumb_downloaded,
                  thumb_url: url_thumb_to_use,
                  thumb_io: file_io_thumb
                }
              when "gif"
                if item_downloaded
                  Listener.bot.api.send_animation(chat_id: chat__id, animation: Faraday::UploadIO.new(temp_files.last.path, exten), caption: capt, parse_mode: "HTML")
                else
                  Listener.bot.api.send_animation(chat_id: chat__id, animation: url_to_use, caption: capt, parse_mode: "HTML")
                end
              when "photo", "image"
                out_compressed_items << { type: "photo", downloaded: item_downloaded, url: url_to_use, io: file_io_comp, exten: exten, caption: capt }
                out_document_items << { type: "document", downloaded: item_downloaded, url: url_to_use, io: file_io_doc, exten: exten }
              end
            end
          end
          
          out_compressed_slices = out_compressed_items.each_slice(10).to_a
          out_document_slices = out_document_items.each_slice(10).to_a
          out_document = out_document_slices
        when "Baraag"
          p "Baraag"
          if response[0].is_a? String
            return
          end
          if !response.is_a? (Array)
            response=[response]
          end
          first_link=response[0][:url]
          count=0
          for individual_response in response
            author_hashtag<<"##{individual_response[:username]}"
            source_lnk<<"<a href=\"#{individual_response[:url]}\">Source baraag#{(count!=0)? " "+(count+1).to_s : ""}</a>"
            cleaned_content = clean_html(individual_response[:post_info]["content"])
            quote<<"<blockquote>#{StandartMessages.transform_string(cleaned_content)}</blockquote>"
            count+=1
          end
          
          if quote.length>=2
            quote=[""]
          end
          
          for i in 0..response.length-1 do
            for j in 0..response[i][:post_info]['media_attachments'].length-1 do
              media=response[i][:post_info]['media_attachments'][j]
              if i==0 and j==0
                capt= "#{quote.join("\n")}\n#{author_hashtag.uniq.join(" ")}\n#{source_lnk.join("\n")}"
              else
                capt=""
              end
              
              url_to_use = media["url"]
              item_downloaded = false
              file_io_comp = nil
              file_io_doc = nil
              exten = "image/jpeg"

              # Baraag/Mastodon хранит превью видео в preview_url
              thumb_downloaded = false
              file_io_thumb = nil
              url_thumb_to_use = (media["type"] == "video") ? media["preview_url"] : nil

              if download_images && media["type"] != "gifv" && url_to_use
                begin
                  ext = url_to_use.split('.').last.split('?').first
                  ext = 'jpg' if ext.to_s.empty? || ext.length > 4
                  exten = (ext == 'mp4' || media["type"] == "video") ? 'video/mp4' : 'image/jpeg'
                  exten = 'image/png' if ext == 'png'
                  
                  tf = Tempfile.new(['baraag_media', ".#{ext}"])
                  tf.binmode
                  URI.open(url_to_use) { |io| tf.write(io.read) }
                  tf.close
                  temp_files << tf
                  
                  file_io_comp = Faraday::UploadIO.new(tf.path, exten)
                  file_io_doc  = Faraday::UploadIO.new(tf.path, exten) if media["type"] == "image"
                  item_downloaded = true

                  if media["type"] == "video" && url_thumb_to_use
                    ext_thumb = url_thumb_to_use.split('.').last.split('?').first
                    ext_thumb = 'jpg' if ext_thumb.to_s.empty? || ext_thumb.length > 4
                    
                    tf_thumb = Tempfile.new(['baraag_thumb', ".#{ext_thumb}"])
                    tf_thumb.binmode
                    URI.open(url_thumb_to_use) { |io| tf_thumb.write(io.read) }
                    tf_thumb.close
                    temp_files << tf_thumb
                    
                    file_io_thumb = Faraday::UploadIO.new(tf_thumb.path, 'image/jpeg')
                    thumb_downloaded = true
                  end
                rescue => e
                  Listener.bot.logger.error("Baraag Download failed: #{e}")
                  item_downloaded = false
                end
              end

              # Извлекаем метаданные размеров/длительности (Baraag/Mastodon хранит их в meta[:original])
              meta = media["meta"] && media["meta"]["original"] ? media["meta"]["original"] : {}
              
              case media["type"]
              when "video"
                out_compressed_items << { 
                  type: "video", 
                  downloaded: item_downloaded, 
                  url: url_to_use, 
                  io: file_io_comp, 
                  exten: exten, 
                  caption: capt,
                  width: meta["width"], 
                  height: meta["height"], 
                  duration: meta["duration"] ? meta["duration"].to_f.round : nil,
                  thumb_downloaded: thumb_downloaded,
                  thumb_url: url_thumb_to_use,
                  thumb_io: file_io_thumb
                }
              when "gifv"
                if item_downloaded
                  Listener.bot.api.send_animation(chat_id: chat__id, animation: Faraday::UploadIO.new(temp_files.last.path, exten), caption: capt, parse_mode: "HTML")
                else
                  Listener.bot.api.send_animation(chat_id: chat__id, animation: url_to_use, caption: capt, parse_mode: "HTML")
                end
              when "image"
                out_compressed_items << { type: "photo", downloaded: item_downloaded, url: url_to_use, io: file_io_comp, exten: exten, caption: capt }
                out_document_items << { type: "document", downloaded: item_downloaded, url: url_to_use, io: file_io_doc, exten: exten }
              end
            end
          end
          
          out_compressed_slices = out_compressed_items.each_slice(10).to_a
          out_document_slices = out_document_items.each_slice(10).to_a
          out_document = out_document_slices
        
        end

        
        #p "....................................."
        #p out_compressed
        #p out_document
        #p "-----------------"
        #p "fffffffffffffffffffffffffffffff"
        
        #cheching if bot is member of comments chat
        comment_chat_available=false
        begin
          temt=Listener.bot.api.get_chat(chat_id:chat__id).linked_chat_id
          Listener.bot.api.get_chat(chat_id:temt)
          self_user_id=Listener.bot.api.get_me().id
          #p "temt=#{temt}__self_user_id=#{self_user_id}"
          chat_memb=Listener.bot.api.get_chat_member(chat_id:temt,user_id:self_user_id)
          if chat_memb.status=="administrator"
            comment_chat_available=true
          end
        rescue
          
        end
        #p "out_document="+out_document.to_s
        if out_document!=[] and comment_chat_available
          p "Comment chat is found, adding uncompressed links"
          Listener.bot.logger.info("Comment chat is found, adding uncompressed links")
          Bot_Globals::Uncompressed_Links<<{source_lnk:first_link,chat__id:chat__id,out_document:out_document,unix_date:Time.now.to_i, temp_files: temp_files}
        end
        #p Bot_Globals::Uncompressed_Links
        begin
          p "out_compressed_slices = #{out_compressed_slices}"
          for slice in out_compressed_slices
            request_sample = { chat_id: chat__id, media: [] }
            media_request_media = []
            media_request_files = []

            p "slice = #{slice}"
            
            slice.each_with_index do |item, i|
              if item[:downloaded]
                attach_name = "file#{i}"
                if item[:type] == "photo"
                  media_request_media << Telegram::Bot::Types::InputMediaPhoto.new(media: "attach://#{attach_name}", caption: item[:caption], parse_mode: "HTML")
                  media_request_files << Hash[:"#{attach_name}", Faraday::FilePart.new(item[:io], item[:exten])]
                else
                  # Обработка видео с загруженным превью
                  attach_thumb_name = "thumb_file#{i}"
                  media_opts = {
                    media: "attach://#{attach_name}",
                    caption: item[:caption],
                    parse_mode: "HTML",
                    supports_streaming: true,
                    width: item[:width],     
                    height: item[:height],   
                    duration: item[:duration] ? item[:duration].round : nil
                  }
                  
                  if item[:thumb_downloaded]
                    # Передаем и thumbnail, и thumb на случай разных версий библиотек
                    media_opts[:thumbnail] = "attach://#{attach_thumb_name}"
                    media_opts[:thumb] = "attach://#{attach_thumb_name}"
                    media_request_files << Hash[:"#{attach_thumb_name}", Faraday::FilePart.new(item[:thumb_io], "image/jpeg")]
                  elsif item[:thumb_url]
                    media_opts[:thumbnail] = item[:thumb_url]
                    media_opts[:thumb] = item[:thumb_url]
                  end
                  
                  media_request_media << Telegram::Bot::Types::InputMediaVideo.new(media_opts)
                  media_request_files << Hash[:"#{attach_name}", Faraday::FilePart.new(item[:io], item[:exten])]
               end
              else
                # Если скачивание отключено или упало, шлем обычным URL
                if item[:type] == "photo"
                  media_request_media << Telegram::Bot::Types::InputMediaPhoto.new(media: item[:url], caption: item[:caption], parse_mode: "HTML")
                else
                  media_opts = {
                    media: item[:url],
                    caption: item[:caption],
                    parse_mode: "HTML",
                    supports_streaming: true,
                    width: item[:width],     
                    height: item[:height],   
                    duration: item[:duration] ? item[:duration].round : nil
                  }
                  if item[:thumb_url]
                    media_opts[:thumbnail] = item[:thumb_url]
                    media_opts[:thumb] = item[:thumb_url]
                  end
                  media_request_media << Telegram::Bot::Types::InputMediaVideo.new(media_opts)
                end
              end
            end
            
            temp = request_sample.dup

            p "media_request_files = #{media_request_files}"

            # Мерджим файлы в корень запроса (магия из твоего рабочего скрипта)
            if media_request_files.any?
              temp = request_sample.merge(media_request_files.inject(&:merge))
            end

            temp[:media] = media_request_media
            p "temp = #{temp}"
            ggg = Listener.bot.api.send_media_group(temp)
            sleep(2)
          end
        rescue Exception=> e
          Listener.bot.logger.error("#{message}\n #{e}\n#{e.backtrace}")
          p "gggggggg"
          p e
          print e.backtrace.join("\n")
          #p e.backtrace
          case e.to_s
          when /Internal Server Error/
              Listener.bot.logger.info(e)
              sleep(1)
              retry
          when /Too Many Requests: retry after/
              ttt=e.to_s[e.to_s.index('parameters: {"retry_after"=>')+28..e.to_s.index('})')-1]
              Listener.bot.logger.warn(e)
              sleep(ttt.to_i)
              retry
          end
          File.write("#{Time.now.to_i}.txt", "#{Time.now}\n #{e}\n#{e.backtrace}\n#{message}")
        end
        #while true 
        #  p Listener.bot.api.get_updates()
        #end



        #trying to send in comments
        if not comment_chat_available #TODO
          return
        end
        return #while upper todo is no completed

        sleep(4)
        begin
          sleep(2*out_compressed.length)
          for upld in out_document
            Listener.bot.api.send_media_group(
            chat_id: chat__id,
            media: upld
            )
            sleep(5)
          end
        rescue Exception=> e
          p e
          #p e.backtrace
          case e.to_s
          when /Internal Server Error/
            Listener.bot.logger.info(e)
            sleep(1)
            Listener.bot.logger.info(e)
            retry
          when /Too Many Requests: retry after/
              ttt=e.to_s[e.to_s.index('parameters: {"retry_after"=>')+28..e.to_s.index('})')-1]
              Listener.bot.logger.warn(e)
              sleep(ttt.to_i)
              retry
          end
          File.write("#{Time.now.to_i}.txt", "#{Time.now}\n #{e}\n#{e.backtrace}\n#{message}")
        
        ensure
          # Закрываем дескрипторы сжатых медиа (они уже отправлены)
          # Закрываем дескрипторы сжатых медиа и их превью
          if defined?(out_compressed_items) && out_compressed_items
            out_compressed_items.each do |item| 
              p "closing item = #{item}"
              item[:io].close if item[:io] && !item[:io].closed?
              item[:thumb_io].close if item[:thumb_io] && !item[:thumb_io].closed? # Закрываем превью
            end
          end
          # Если комменты недоступны, то несжатые файлы нам больше не нужны — удаляем их сразу.
          # Если комменты доступны, файлы остаются жить в Bot_Globals до отправки в чат.
          comment_chat_saved = defined?(comment_chat_available) && comment_chat_available && out_document_slices.any?
          unless comment_chat_saved
            if defined?(out_document_items) && out_document_items
              out_document_items.each { |item| item[:io].close if item[:io] && !item[:io].closed? }
            end
            if defined?(temp_files) && temp_files
              temp_files.each { |tf| tf.unlink rescue nil }
            end
          end
        end
        #p out_document
        #p out_photo
        
        #p out
      end
      def get_fxtwitter_response(link)
        output_response_array=[]
        link=link.split("\n")
        for s in link do
          type="photo"
          source_lnk=""+s
          if s.include?"/photo"
            s=s[0..s.index("/photo")-1]
            type="photo"
          elsif s.include?"/video"
            s=s[0..s.index("/video")-1]
          end
          
          #message.text

          api_link="https://api.fxtwitter.com"#"http://127.0.0.1:8787"#

          tw_link=case s
          when /https:\/\/twitter.com/
              s.to_s.sub! "https://twitter.com",api_link
          when /https:\/\/fxtwitter.com/
              s.to_s.sub! "https://fxtwitter.com",api_link
          when /https:\/\/x.com/
              s.to_s.sub! "https://x.com", api_link
          when /https:\/\/fixupx.com/
              s.to_s.sub! "https://fixupx.com", api_link
          end
          #tw_link+='/en'
          #p tw_link
          #response = Faraday.get("#{tw_link}",{}, { 'User-Agent' => 'twitter_images_telegrambot/1.0' }) OLD
          begin
            response=Faraday.new(tw_link, headers: { 'User-Agent' => 'twitter_images_telegrambot/1.0' }).get
            response= JSON.parse(response.body) 
          rescue Exception=>e
            if e.to_s.include? "Blocking operation timed out"
              sleep(1)
              retry
            end
            if e.to_s.include? "unexpected character: '<!DOCTYPE"
              sleep(1)
              retry
            end
          end
          #p response
          #p response
          #if response==nil
          #  return nil
          #end
          
          #p response
          if response["code"]==404
            return nil
          end
          if false#response["code"]==404   JUST IN CASE. Send API link to telegram to get file, then download this file to get request. useful when there is problems with connecting to fxtwitter
            a=Listener::Response.send_document((tw_link.to_s.sub! "http://127.0.0.1:8787","https://api.fxtwitter.com"),TelegramConstants::ERROR_CHANNEL_ID)#"https://api.fxtwitter.com/nezulet/status/1565910020142899201")  
            e= a["result"]["document"]["file_id"]
            #p a
            file=Listener.bot.api.get_file(file_id:e).dig('result','file_path').to_s
            response= URI.open("https://api.telegram.org/file/bot#{TelegramConstants::API_KEY}/#{file}").read
            #p a["result"]["message_id"]
            #Listener::Response.delete_message(a["result"]["message_id"])
            Listener.bot.api.delete_message(chat_id:TelegramConstants::ERROR_CHANNEL_ID, message_id:a["result"]["message_id"])
            response=JSON.parse(response)
          end
          if response["tweet"].has_key? "media"
            output_response_array<< response
          else 
            return [response["tweet"]["text"]]
          end
        end
        #p response
        return output_response_array
        #p response
        #p response["tweet"]["media"]["videos"][0]["url"]
      end
      def process(message)
        #p "JJJJJ=";p message
        case message.photo
        when ""
        else
          #Listener::Response.std_message(message,"#{message.photo}")
          p message.photo
        end
        case message.text
        when '/start', 'команды','/commands','/how_to'
          Listener::Response.std_message(message,"https://telegra.ph/How-to-twitter-embed-bot-05-22")
        when '/ping'
          Listener::Response.std_message(message,"pong")
        when '/open_source'
          Listener::Response.std_message(message,"Contribute on\nhttps://github.com/ALEKSEYR554/twitter_to_images_telegram")
        when "/remove_cache"
          return if not Codes.is_admin?(message.from)
          for i in Bot_Globals::Uncompressed_Links
            Bot_Globals::Uncompressed_Links.delete(i)
          end
          Listener::Response.std_message(message,Bot_Globals::Uncompressed_Links)
        when /"code":200,"message":"OK","tweet"/
          response= message.text
          response= JSON.parse(response)

          chat__id = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
          begin
          Listener.bot.api.delete_message(chat_id:chat__id, message_id:message.message_id)
          rescue Exception=>e
            Listener.bot.logger(e)
          end
          
          StandartMessages.response_to_images(message,response,"twitter")
          return
        when /https:\/\/baraag.net\/(.*?)\/[0-9]+/
          #return
          if not message.from
            chat__id = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
            begin
              Listener.bot.api.delete_message(chat_id:chat__id, message_id:message.message_id)
            rescue Exception => e
              Listener.bot.logger.warn(e)
              return
            end
            link=message.text
            link=link.split("\n")
            Listener.bot.logger.info("baraag=#{link}")
            response=[]
            for s in link
              #url = "https://baraag.net/@Phinci/114570991029426425"
              url=s
              #username = url.match(%r{https:\/\/baraag.net\/(.*?)\/[0-9]+})[1]

              post_id=/\/[0-9]+/.match(url)[0][1..]
              post_info=Faraday.get("https://baraag.net/api/v1/statuses/#{post_id}").body

              post_info= JSON.parse(post_info)#["thread"]["post"]
              return if post_info["media_attachments"].empty?
              
              username = post_info["account"]["username"]
              
              response.append({"post_info":post_info,"username":username,"post_id":post_id,"url":url})
            end
            p response
            response_to_images(message,response,"Baraag")
          end
        when /https:\/\/bsky\.app\/profile\/(.*?)\/post/
          p "ffffffffffffffffffff"
          if not message.from
            chat__id = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
            begin
              Listener.bot.api.delete_message(chat_id:chat__id, message_id:message.message_id)
            rescue Exception => e
              Listener.bot.logger.warn(e)
              return
            end
            link=message.text
            link=link.split("\n")
            Listener.bot.logger.info("bluesky=#{link}")
            response=[]
            for s in link
              begin
                response=Faraday.new(tw_link, headers: { 'User-Agent' => 'twitter_images_telegrambot/1.0' }).get
              rescue Exception=>e
                if e.to_s.include? "Blocking operation timed out"
                  sleep(1)
                  retry
                end
              end
              #url = "https://bsky.app/profile/mishacak3s.bsky.social/post/3l6x5hqqpna2b"
              url=s
              username = url.match(%r{profile/(.*?)/post})[1]
              post_id=url.match(%r{post/(.*)})[1]
              did= Faraday.get("https://#{username}/.well-known/atproto-did").body
              post_info=Faraday.get("https://api.fxbsky.app/2/status/#{username}/#{post_id}").body
              post_info= JSON.parse(post_info)
              return if post_info["status"]["media"].nil?

              response.append({"post_info":post_info,"username":username,"post_id":post_id,"url":url})
            end
            p response
            response_to_images(message,response,"Bluesky")
          end

        when /https:\/\/(fxtwitter|twitter|x)\.com/ #https:\/\/(fx|)twitter\.com.*\/photo\/
          #begin
          source_lnk=""
          tw_link=""
          if not message.from#channel return nil
            #p message
            #return if message.text.include? "{\"code\":200"
            s=message.text#https://twitter.com/i/status/1731506067702686034
            #p message
            Listener.bot.logger.info(message.chat)
            chat__id = (defined?message.chat.id) ? message.chat.id : message.message.chat.id

            #if not [-1002091928465].include? chat__id

            #p chat__id
            begin
              Listener.bot.api.delete_message(chat_id:chat__id, message_id:message.message_id)
            rescue Exception => e
              Listener.bot.logger.warn(e)
              return
            end

            resp=StandartMessages.get_fxtwitter_response(s)
            return if not resp


            StandartMessages.response_to_images(message,resp,"twitter")
            return
          end
          #rescue Exception => e
            #Listener::Response.std_message("#{e}",TelegramConstants::ERROR_CHANNEL_ID)
            #Listener::Response.std_message("#{e.backtrace}",TelegramConstants::ERROR_CHANNEL_ID)
            #Listener::Response.std_message("#{tw_link.to_s.sub! "http://127.0.0.1:8787","https://api.fxtwitter.com"}",TelegramConstants::ERROR_CHANNEL_ID)
          #end
        when "ping"
          #p message
          Listener::Response.std_message(message,"pong")
        when "/add_to_whitelist"
          return if not Codes.is_admin?(message.from)
          Listener::Response.force_reply_message(message,"Send_id")
        when "/send_latest_log"
          return if not Codes.is_admin?(message.from)
          io_log=Faraday::UploadIO.new('log.log', 'log/log')
          Listener::Response.send_document(message,io_log)
          io_log.close
        when "/send_other_logs"
          return if not Codes.is_admin?(message.from)
          io_log=Faraday::UploadIO.new('log.log.0', 'log/log')
          Listener::Response.send_document(message,io_log)
          io_log.close
          io_log=Faraday::UploadIO.new('log.log.1', 'log/log')
          Listener::Response.send_document(message,io_log)
          io_log.close
        when "test"
          a=Listener::Response.send_document(message,"https://api.fxtwitter.com/saberwotd/status/1772533531903766860/photo/1")  
          a= a["result"]["document"]["file_id"]
          file=Listener.bot.api.get_file(file_id:a).dig('result','file_path').to_s
          res= URI.open("https://api.telegram.org/file/bot#{TelegramConstants::API_KEY}/#{file}").read
          #p JSON.parse(res)
          #file=Listener.bot.api.get_file(file_id:aa["document"]["file_id"])
          #p file
        else
          unless message.reply_to_message.nil?
            case message.reply_to_message.text
            when /Send_id/
              return if not Codes.is_admin?(message.from)
              if message.text.to_i !=0
                File.write('whitelist.txt', "\n#{message.text}", mode: 'a+')
              end
            end
          end        #Response.std_message "#{message.forward_from_chat.id}"
          #unless message.caption.nil?
          #  if message.caption.include? "t.me"
          #    Listener::Response.edit_message_caption(message,nil)
          #  end
          #end
        end
      end
      module_function(
        :process,
        :transform_string,
        :response_to_images,
        :get_fxtwitter_response,
        :clean_html
      )

    end
  end
end
