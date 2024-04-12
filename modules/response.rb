class FishSocket
  module Listener
    # This module assigned to responses from bot
    module Response
      def std_message(message, text, chat_id=nil)
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id

        chat = chat_id if chat_id
        Listener.bot.api.send_message(
          parse_mode: 'html',
          chat_id: chat,
          text: text
        )
      end
      def edit_message_caption(message, text, chat_id=false)
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
        chat = chat_id if chat_id
        message_id=message.message_id
        Listener.bot.api.editMessageCaption(
          chat_id: chat,
          message_id:message_id,
          caption:text,
          parse_mode:'html'
        )
      end
      def send_media_group(message, file_array,chat_id=false)
        return false if file_array.length()<2
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_media_group(
          chat_id: chat,
          media: file_array
        )
      end
      def edit_message(message,text,chat_id=nil)
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
        message_id=message.message_id#message.
        chat = chat_id if chat_id
        Listener.bot.api.editMessageText(
          parse_mode: 'html',
          chat_id: chat,
          message_id:message_id,
          text: text
        )
      end
      def send_media_group(message,file_array,text=nil,chat_id=false)
        return false if file_array.length()<2
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
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
      def forward_message(message, to_chat_id, type="", add="")
        from_chat_id=message.chat.id
        message_id =message.message_id
        Listener.bot.api.forward_message(
          chat_id:to_chat_id,
          from_chat_id:from_chat_id,
          message_id: message_id,
          disable_notification:true
        )
      end
      def send_animation(message, file_id, chat_id = false )
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_animation(
          parse_mode: 'html',
          chat_id: chat,
          animation: file_id
        )
      end
      def send_photo(message, file_id, chat_id = false,caption="" )
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_photo(
          parse_mode: 'html',
          chat_id: chat,
          photo: file_id,
          caption: caption.to_s
        )
      end
      def send_document(message, file_id, chat_id = false )
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_document(
          parse_mode: 'html',
          chat_id: chat,
          document: file_id
        )
      end
      def send_video(message, file_id, chat_id = false )
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
        chat = chat_id if chat_id
        Listener.bot.api.send_video(
          parse_mode: 'html',
          chat_id: chat,
          video: file_id.to_s
        )
      end
      def force_reply_message(message, text, chat_id = false)
        chat = (defined?message.chat.id) ? message.chat.id : message.message.chat.id
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
