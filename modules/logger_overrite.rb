class FishSocket
  def logger_overrite  
    Telegram::Bot::Client.module_eval do
      def log_incoming_message(message)
        uid = message.respond_to?(:from) && message.from ? message.from.id : nil
        #print("FUUUUUUUUUUUUUUUUUUUUUUUUCK\n\n\n")
        #p message.class
        case message.class.to_s
        when "Telegram::Bot::Types::InlineQuery"
            logger.info(
                format('InlineQuery: text="%<message>s" uid=%<uid>s', message: message, uid: uid)
            )
        when "Telegram::Bot::Types::Message"
          #p "telegram message"
            if message.sender_chat
              if message.sender_chat.type=="channel"
                uid=message.sender_chat.id
                username=message.sender_chat.username ? message.sender_chat.username : "no "
                title=message.sender_chat.title
                logger.info(
                    format('Channel: text="%<message>s" username=%<username>s title=%<title>s id=%<uid>s', message: message, username: username, title:title, uid:uid)
                )
              end
            else
              logger.info(
                  format('message: text="%<message>s" uid=%<uid>s', message: message, uid: uid)
              )
            end
        else
          logger.info(
            format('message: text="%<message>s" uid=%<uid>s', message: message, uid: uid)
          )
        end
      end
    end
  end
end