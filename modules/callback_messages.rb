class FishSocket
  module Listener
    # This module assigned to processing all callback messages
    module CallbackMessages
      attr_accessor :callback_message

      def process(message)
        self.callback_message = message.message
        case message.data
        when 'EXAMPLE_PLACEHOLDER'
          Listener::Response.force_reply_message(message,"Введите айди человека")
          Listener::Security.answer_callback_query
        end
      end

      module_function(
          :process,
          :callback_message,
          :callback_message=
      )
    end
  end
end
