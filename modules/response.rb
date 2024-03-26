class FishSocket
  module Listener
    # This module assigned to responses from bot
    module Response
      def std_message(message, chat_id=nil)
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id

        chat = chat_id if chat_id
        Listener.bot.api.send_message(
          parse_mode: 'html',
          chat_id: chat,
          text: message
        )
      end
      def edit_message_caption(text,chat_id=false)
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        chat = chat_id if chat_id
        message_id=Listener.message.message_id
        Listener.bot.api.editMessageCaption(
          chat_id: chat,
          message_id:message_id,
          caption:text,
          parse_mode:'html'
        )
      end
      def send_media_group(file_array,chat_id=false)
        return false if file_array.length()<2
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_media_group(
          chat_id: chat,
          media: file_array
        )
      end
      def edit_message(text,chat_id=nil)
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        message_id=Listener.message.message_id#message.
        chat = chat_id if chat_id
        Listener.bot.api.editMessageText(
          parse_mode: 'html',
          chat_id: chat,
          message_id:message_id,
          text: text
        )
      end
      def fully_copy_and_send_message(chat_id) #copypaste from another bot
        a=Listener::Codes.file_id_get
        count=a.each_slice(10).to_a.length#split array to arrays by 10 elements
        for j in 1..count do
          caption= Listener.bot.api.get_updates.dig("result",0,"message","caption").nil? ? "" :Listener.bot.api.get_updates.dig("result",0,"message","caption").to_s
          #File.write("twetw.txt","#{Listener.bot.api.get_updates()}")
          send_smth=false
          out=[]
          a.map{ |e|
             if e[1]=="video" or e[1]=="photo"
               out << e
             elsif e[1]=="document"
               Listener::Response.send_document("#{e[0]}",chat_id)
               send_smth=true
             elsif e[1]=="text"
               Listener::Response.std_message("#{e[0]}",chat_id)
               send_smth=true
             end
           }
          return false if out==[] and not send_smth # main check
          if out.length()==1
           case out[0][1]
             when "photo"
               Listener::Response.send_photo(out[0][0],chat_id,caption: caption)
               send_smth=true
             when "video"
               Listener::Response.send_video(out[0][0],chat_id)
                send_smth=true
           end
          elsif out.length()>1
            photo_yes=false
           for i in 0..out.length()-1
             case out[i][1]
             when "photo"
               if photo_yes
                 out[i]=Telegram::Bot::Types::InputMediaPhoto.new(media:"#{out[i][0]}")
               else
                 out[i]=Telegram::Bot::Types::InputMediaPhoto.new(media:"#{out[i][0]}",caption:caption)
                 photo_yes=true
               end
             when "video"
               out[i]=Telegram::Bot::Types::InputMediaVideo.new(media:"#{out[i][0]}")
             end
           end
           #File.write("dads.txt","#{out}")
           Listener::Response.send_media_group(out,chat_id) if not send_smth==true
           #send_smth=true
          end
        end
      end
      def send_media_group(file_array,text=nil,chat_id=false)
        return false if file_array.length()<2
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        chat = chat_id if chat_id
        if text
          Listener.bot.api.send_media_group(
            caption: text,
            chat_id: chat,
            media: file_array
          )
        else
          Listener.bot.api.send_media_group(
            chat_id: chat,
            media: file_array
          )
        end
      end
      def forward_message(to_chat_id, type="", add="")
        from_chat_id=Listener.message.chat.id
        message_id =Listener.message.message_id
        Listener.bot.api.forward_message(
          chat_id:to_chat_id,
          from_chat_id:from_chat_id,
          message_id: message_id,
          disable_notification:true
        )
      end
      def send_animation(file_id, chat_id = false )
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_animation(
          parse_mode: 'html',
          chat_id: chat,
          animation: file_id
        )
      end
      def send_photo(file_id, chat_id = false,caption="" )
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_photo(
          parse_mode: 'html',
          chat_id: chat,
          photo: file_id,
          caption: caption.to_s
        )
      end
      def send_document(file_id, chat_id = false )
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_document(
          parse_mode: 'html',
          chat_id: chat,
          document: file_id
        )
      end
      def send_video(file_id, chat_id = false )
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_video(
          parse_mode: 'html',
          chat_id: chat,
          video: file_id.to_s
        )
      end
      def force_reply_message(text, chat_id = false)
        chat = (defined?Listener.message.chat.id) ? Listener.message.chat.id : Listener.message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_message(
          parse_mode: 'html',
          chat_id: chat,
          text: text,
          reply_markup: Telegram::Bot::Types::ForceReply.new(
            force_reply: true,
            selective: true
          )
        )
      end

      module_function(
        :std_message,
        :force_reply_message,
        :send_document,
        :edit_message,
        :send_photo,
        :send_video,
        :edit_message_caption,
        :send_media_group,
        :send_animation,
        :forward_message,
        :send_media_group
      )
    end
  end
end
