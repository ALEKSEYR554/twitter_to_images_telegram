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
      def response_to_images(response,tw_link="")
        quote=""
        out=[]
        source_lnk=""
        #p response
        chat__id = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id

        if response["code"]==404
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
        author_hashtag=response["tweet"]["author"]["screen_name"]
        source_lnk=response["tweet"]["url"]#""+Listener.message.text        
        if response["tweet"]["text"]!=nil
          quote=if response["tweet"].has_key? "translation"
              StandartMessages.transform_string(response["tweet"]["translation"]["text"])
          else
              StandartMessages.transform_string(response["tweet"]["text"])
          end
        end
        if response["tweet"]["media"].has_key? "videos"#/\/i\/status/.match? s
          Listener.bot.api.send_animation(
            chat_id:chat__id,
            animation: response["tweet"]["media"]["videos"][0]["url"],
            caption:"<blockquote>#{quote}</blockquote>\n##{author_hashtag}\n<a href=\"#{source_lnk}\">Source twitter</a>",
            parse_mode:"HTML"
          )
          return
        end

        response["tweet"]["media"]["photos"].each do |img_hash|
            out << img_hash["url"]
        end
        out_photo=[];out_document=[]
        for i in 0..out.length-1 do
          out_document<<Telegram::Bot::Types::InputMediaDocument.new(media:"#{out[i]}:orig")
          if i==0
            out_photo<<Telegram::Bot::Types::InputMediaPhoto.new(media:"#{out[i]}:orig",
            parse_mode:"HTML",
            caption: "<blockquote>#{quote}</blockquote>\n##{author_hashtag}\n<a href=\"#{source_lnk}\">Source twitter</a>") 
          else
            out_photo<<Telegram::Bot::Types::InputMediaPhoto.new(media:"#{out[i]}:orig") 
          end
        end
        #p out_document
        #p out_photo
        Listener.bot.api.send_media_group(
          chat_id: chat__id,
          media: out_photo
        )
        Listener.bot.api.send_media_group(
          chat_id: chat__id,
          media: out_document
        )
        #p out
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
            type="photo"
            if s.include?"/photo"
              s=s[0..s.index("/photo")-1]
              type="photo"
            elsif s.include?"/i/status/"
              type="video"
            end
            
            source_lnk=""+Listener.message.text
            #p Listener.message
            chat__id = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
            #p chat__id
            Listener.bot.api.delete_message(chat_id:chat__id, message_id:Listener.message.message_id)

            api_link="http://127.0.0.1:8787"#"https://api.fxtwitter.com"

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
            tw_link+='/en'
            #p tw_link
            #response = Faraday.get("#{tw_link}",{}, { 'User-Agent' => 'twitter_images_telegrambot/1.0' }) OLD
            response=Faraday.new(tw_link, headers: { 'User-Agent' => 'twitter_images_telegrambot/1.0' }).get
            #p response
            response= JSON.parse(response.body)
            #p response
            #p response["tweet"]["media"]["videos"][0]["url"]
            StandartMessages.response_to_images(response,tw_link)
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
        when "test"
          a=Listener::Response.send_document("https://api.fxtwitter.com/nezulet/status/1565910020142899201")  
          a= a["result"]["document"]["file_id"]
          file=Listener.bot.api.get_file(file_id:a).dig('result','file_path').to_s
          res= URI.open("https://api.telegram.org/file/bot#{TelegramConstants::API_KEY}/#{file}").read
          p JSON.parse(res)
          #file=Listener.bot.api.get_file(file_id:aa["document"]["file_id"])
          #p file
        else
          unless Listener.message.reply_to_message.nil?
            case Listener.message.reply_to_message.text
            when /file_id_send/
              Listener::Response.send_photo(Listener.message.text.to_s)
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
        :response_to_images
      )

    end
  end
end
