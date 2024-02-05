class FishSocket
  module Listener
    # Module for checks
    module Security
      def message_is_new(start_time, message)
        message_time = (defined? message.date) ? message.date : message.message.date
        message_time.to_i > start_time
      end
      def answer_callback_query()
        id=Listener.bot.api.get_updates.dig("result",0,"callback_query","id")
        from=Listener.bot.api.get_updates.dig("result",0,"callback_query","from","id")
        #File.write("callback.txt","#{Listener.bot.api.get_updates}")
        #p id
        #p from
        Listener.bot.api.answerCallbackQuery(callback_query_id:id, cache_time:1)#,from:from, cache_time:2)
      end
      def is_blacklisted(message,bot)
        return false if message.from==nil
        File.open("blacklist.txt").each_line do |line|
          if message.from.id.to_s == line.to_s[0..-2]
            return true
          end
        end
        return false
      end
      def message_too_far
        message_date = (defined? Listener.message.date) ? Listener.message.date : Listener.message.message.date
        message_delay = Time.now.to_i - message_date.to_i
        # if message delay less then 5 min then processing message, else ignore
        message_delay > (30 * 60)
      end
      module_function :message_is_new, :message_too_far, :is_blacklisted,:answer_callback_query
    end
  end
end
