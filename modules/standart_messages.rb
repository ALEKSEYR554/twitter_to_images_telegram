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
      def response_to_images(response)
        #p "----------------"
        out=[]
        if response=="IT IS TEXT"
          return
        end
        p response
        if !response.is_a? (Array)
          response=[response]
        end
        chat__id = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        p "1"
        author_hashtag=[]
        source_lnk=[]
        quote=[]
        #p response
        count=0
        for individual_response in response
          author_hashtag<<"##{individual_response["tweet"]["author"]["screen_name"]}"

          source_lnk<<"<a href=\"#{individual_response["tweet"]["url"]}\">Source twitter#{(count!=0)? " "+count.to_s : ""}</a>"#""+Listener.message.text        

          quote<<"<blockquote>#{StandartMessages.transform_string(individual_response["tweet"]["text"])}</blockquote>"
          count+=1

          #if individual_response["tweet"]["media"].has_key? "videos"#/\/i\/status/.match? s
          #  Listener.bot.api.send_animation(
          #    chat_id:chat__id,
          #    animation: individual_response["tweet"]["media"]["videos"][0]["url"],
          #    caption:"#{quote}\n#{author_hashtag}\n#{source_lnk}",
          #    parse_mode:"HTML"
          #  )
          #  return
          #end
          p "2"
          #individual_response["tweet"]["media"]["photos"].each do |img_hash|
          #  out << img_hash["url"]
          #end
        end
        
        #out=out.each_slice(10).to_a
        
        out_compressed=[];out_document=[]
        p "FUUUUUUUUUUUU"
        #p quote
        #p author_hashtag
        #p source_lnk
        if quote.length>=2
          quote=[""]
        end
        for i in 0..response.length-1 do
          #File.open("#{out[i][out[i].index('/media/')+7..]}", 'wb') { |fp| fp.write(response.body) }
          #IO.copy_stream(URI.open("#{out[i]}:orig"), "./test_files/#{out[i][out[i].index('/media/')+7..]}")
          #p response
          for j in 0..response[i]['tweet']["media"]['all'].length-1 do
            media=response[i]['tweet']["media"]['all'][j]
            if i==0 and j==0
              capt= "#{quote.join("\n")}\n#{author_hashtag.uniq.join(" ")}\n#{source_lnk.join("\n\n")}"
            else
              capt=""
            end
            case media["type"]
            when "video"
              out_compressed<<Telegram::Bot::Types::InputMediaVideo.new(
                  type:"video",
                  media:media["url"],
                  caption:capt,
                  parse_mode:"HTML"
                  )
            when "gif"
              Listener.bot.api.send_animation(
                chat_id:chat__id,
                animation: individual_response["tweet"]["media"]["videos"][j]["url"],
                caption:capt,
                parse_mode:"HTML"
              )
            when "photo"
              out_compressed<<Telegram::Bot::Types::InputMediaPhoto.new(
                    media:"#{media["url"]}:orig",
                    caption:capt,
                    parse_mode:"HTML"
                    )
              out_document<<Telegram::Bot::Types::InputMediaDocument.new(
                media:"#{media["url"]}:orig"
                )
            end
          end
        end
        out_compressed=out_compressed.each_slice(10).to_a
        out_document=out_document.each_slice(10).to_a
        p "....................................."
        p out_compressed
        p out_document
        p "-----------------"
        begin
          for upld in out_compressed
            p "cmp"
            ggg=Listener.bot.api.send_media_group(
            chat_id: chat__id,
            media: upld
            )
            p ggg
            #File.write("111.txt","#{ggg}")
            sleep(2)
          end
        rescue Exception=> e
          p e
          #p e.backtrace
          case e.to_s
          when /Internal Server Error/
              Listener.bot.logger.info(e)
              sleep(1)
              retry
          when /Too Many Requests: retry after/
              ttt=e.to_s[e.to_s.index('parameters: "{"retry_after"=>')+29..e.to_s.index('}")')-1]
              Listener.bot.logger.warn(e)
              sleep(ttt.to_i)
              retry
          end
          File.write("#{Time.now.to_i}.txt", "#{Time.now}\n #{e}\n#{result}")
        end
        #while true 
        #  p Listener.bot.api.get_updates()
        #end
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
              ttt=e.to_s[e.to_s.index('parameters: "{"retry_after"=>')+29..e.to_s.index('}")')-1]
              Listener.bot.logger.warn(e)
              sleep(ttt.to_i)
              retry
          end
          File.write("#{Time.now.to_i}.txt", "#{Time.now}\n #{e}\n#{result}")
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
          
          #Listener.message.text

          api_link="https://api.fxtwitter.com"#"http://127.0.0.1:8787"#

          tw_link=case s
          when /https:\/\/twitter.com/
              s.to_s.sub! "https://twitter.com",api_link
          when /https:\/\/fxtwitter.com/
              s.to_s.sub! "https://fxtwitter.com",api_link
          when /https:\/\/x.com/
              s.to_s.sub! "https://x.com", api_link
          when /https:\/\/x.com/
              s.to_s.sub! "https://fixupx.com", api_link
          end
          #tw_link+='/en'
          #p tw_link
          #response = Faraday.get("#{tw_link}",{}, { 'User-Agent' => 'twitter_images_telegrambot/1.0' }) OLD
          begin
          response=Faraday.new(tw_link, headers: { 'User-Agent' => 'twitter_images_telegrambot/1.0' }).get
          rescue Exception=>e
            if e.to_s.include? "Blocking operation timed out"
              sleep(1)
              retry
            end
          end
          #p response
          #p response
          response= JSON.parse(response.body) 

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
            return "IT IS TEXT"
          end
        end
        return output_response_array
        #p response
        #p response["tweet"]["media"]["videos"][0]["url"]
      end
      def process
        if Listener.message.text.to_s.include? "/start code_check_"
          @code=Listener.message.text.to_s[18..-1]
          Listener.message.text="/start code_check_"
        end
        if Listener.message.forward_from_chat
          return
        end
        if Listener.message.forward_from
          return
        end
        case Listener.message.text
        when '/start', 'команды','/commands'
          Listener::Response.std_message("Обязательно прочитайте /rules.\n Используйте меню комманд слева от поля ввода сообщения")
        when /"code":200,"message":"OK","tweet"/
          response= Listener.message.text
          response= JSON.parse(response)

          chat__id = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
          Listener.bot.api.delete_message(chat_id:chat__id, message_id:Listener.message.message_id)
          

          StandartMessages.response_to_images(response)
          return
          
        when /https:\/\/(fxtwitter|twitter|x|fixupx)\.com/ #https:\/\/(fx|)twitter\.com.*\/photo\/
          #begin
          source_lnk=""
          tw_link=""
          if not Listener.message.from#channel return nil
            #p Listener.message
            #return if Listener.message.text.include? "{\"code\":200"
            s=Listener.message.text#https://twitter.com/i/status/1731506067702686034
            #p Listener.message
            chat__id = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id

            #if not [-1002091928465].include? chat__id

            #p chat__id
            begin
              Listener.bot.api.delete_message(chat_id:chat__id, message_id:Listener.message.message_id)
            rescue Exception=>e
              Listener.bot.logger.warn(e)
              return
            end


            resp=StandartMessages.get_fxtwitter_response(s)


            StandartMessages.response_to_images(resp)
            return
          end
          #rescue Exception => e
            #Listener::Response.std_message("#{e}",TelegramConstants::ERROR_CHANNEL_ID)
            #Listener::Response.std_message("#{e.backtrace}",TelegramConstants::ERROR_CHANNEL_ID)
            #Listener::Response.std_message("#{tw_link.to_s.sub! "http://127.0.0.1:8787","https://api.fxtwitter.com"}",TelegramConstants::ERROR_CHANNEL_ID)
          #end
        when "ping"
          #p Listener.message
          Listener::Response.std_message("pong")
        when "/add_to_whitelist"
          return if not Codes.is_admin?(Listener.message.from)
          Listener::Response.force_reply_message("Send_id")
        when "/send_latest_log"
          return if not Codes.is_admin?(Listener.message.from)
          io_log=Faraday::UploadIO.new('log.log', 'log/log')
          Listener::Response.send_document(io_log)
          io_log.close
        when "test"
          a=Listener::Response.send_document("https://api.fxtwitter.com/saberwotd/status/1772533531903766860/photo/1")  
          a= a["result"]["document"]["file_id"]
          file=Listener.bot.api.get_file(file_id:a).dig('result','file_path').to_s
          res= URI.open("https://api.telegram.org/file/bot#{TelegramConstants::API_KEY}/#{file}").read
          #p JSON.parse(res)
          #file=Listener.bot.api.get_file(file_id:aa["document"]["file_id"])
          #p file
        else
          unless Listener.message.reply_to_message.nil?
            case Listener.message.reply_to_message.text
            when /Send_id/
              return if not Codes.is_admin?(Listener.message.from)
              if Listener.message.text.to_i !=0
                File.write('whitelist.txt', "\n#{Listener.message.text}", mode: 'a+')
              end
            end
          end        #Response.std_message "#{Listener.message.forward_from_chat.id}"
          unless Listener.message.caption.nil?
            if Listener.message.caption.include? "t.me"
              Listener::Response.edit_message_caption(nil)
            end
          end
        end
      end
      module_function(
        :process,
        :transform_string,
        :response_to_images,
        :get_fxtwitter_response
      )

    end
  end
end
