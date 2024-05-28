class FishSocket
    module Listener
      # This module assigned to processing all InlineQuery requests
        module InlineQuery
            def process(message)
                
                #p "inline=#{message}" 



                #EXAMPLE
                eXAMPLE_code='''
                if not Codes.is_in_whitelist?(message.from)
                    begin
                    Listener.bot.api.answer_inline_query(
                            inline_query_id: message.id,
                            results: [Telegram::Bot::Types::InlineQueryResultArticle.new(
                                id: "0",
                                title: "You need to be in whitelist to access this bot",
                                input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(message_text: "I thought it was obvious from title that you are not in a whitelist")
                            )
                            ]
                        )
                    rescue Exception=>e
                        #p e
                    end
                    return
                end
                '''
                #p message.query
                case message.query
                when /https:\/\/(fxtwitter|twitter|x|fixupx)\.com/#.match?("#{message}")#.include? "https://twitter.com" or message.include? "https://x.com"
                    p message.query
                    begin
                    response=StandartMessages.get_fxtwitter_response("#{message.query}")
                    rescue Exception=>e
                        Listener.bot.logger.warn("Error in getting fxtwitter response while in inline query")
                        Listener.bot.logger.error("#{message}\n #{e}\n#{e.backtrace}")
                    end
                    if !response
                        Listener.bot.api.answer_inline_query(
                                inline_query_id: message.id,
                                results: [Telegram::Bot::Types::InlineQueryResultArticle.new(
                                    id: "0",
                                    title: "invalid link",
                                    input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(
                                        message_text: "invalid link",
                                        parse_mode:"html",
                                        link_preview_options:Telegram::Bot::Types::LinkPreviewOptions.new(
                                            is_disabled:true)
                                        )
                                )
                                ]
                            )
                        return
                    end
                    response=response[0]
                    #p "???"
                    #p "---"
                    #p response
                    #p "---"
                    p "respin==#{response}"
                    if response.is_a? String
                        begin
                        Listener.bot.api.answer_inline_query(
                                inline_query_id: message.id,
                                results: [Telegram::Bot::Types::InlineQueryResultArticle.new(
                                    id: "0",
                                    title: "Click me to send text starting with #{response[0..10]}",
                                    input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(
                                        message_text: "<blockquote>#{StandartMessages.transform_string(response)}</blockquote>\n<a href=\"#{StandartMessages.transform_string(message.query)}\">twitter</a>",
                                        parse_mode:"html",
                                        link_preview_options:Telegram::Bot::Types::LinkPreviewOptions.new(
                                            is_disabled:true)
                                        )
                                )
                                ]
                            )
                        rescue Exception=>e
                            #p e
                        end
                        return
                    end
                    #p response
                    return if response["code"]==404
                    #p "fuck"
                    
                    answer_inline=[]
                    for i in 0..response['tweet']["media"]['all'].length-1 do
                        media=response['tweet']["media"]['all'][i]
                        #capt="#{i+1}/#{response['tweet']["media"]['all'].length}\n<a href=\"#{message.query}\">Twitter</a>"
                        capt="<a href=\"#{message.query}\">Twitter</a>"
                        #if !Security::is_subscribe(message.from)
                        #    #p "unsub"
                        #    capt+="\n#{TelegramConstants::CHANNEL_LINK}\nSubscribe to disable it" unless Codes.is_in_whitelist?(message.from)
                        #end
                        
                        answer_inline << case media["type"]
                            when "video"
                                Telegram::Bot::Types::InlineQueryResultVideo.new(
                                    id:"#{i}",
                                    video_url:media["url"],
                                    mime_type:"video/mp4",
                                    caption:capt,
                                    parse_mode:"HTML",
                                    video_width:media["width"],
                                    video_height:media["height"],
                                    thumbnail_url:media["thumbnail_url"],
                                    title:"Twitter video"
                                    )
                            when "gif"
                                Telegram::Bot::Types::InlineQueryResultMpeg4Gif.new(
                                    id:"#{i}",
                                    mpeg4_url:media["url"],
                                    mpeg4_width:media["width"],
                                    caption:capt,
                                    parse_mode:"HTML",
                                    mpeg4_height:media["height"],
                                    thumbnail_url:media["thumbnail_url"]
                                    )
                            when "photo"
                                Telegram::Bot::Types::InlineQueryResultPhoto.new(
                                    id:"#{i}",
                                    photo_url:"#{media["url"]}:orig",
                                    photo_width:media["width"],
                                    caption:capt,
                                    parse_mode:"HTML",
                                    photo_height:media["height"],
                                    thumbnail_url:"#{media["url"]}:orig"
                                    )
                        end
                    end
                    #if response['tweet']["media"].has_key? "mosaic"
                    #    answer_inline<<
                    #end
                    #answer_inline=[Telegram::Bot::Types::InlineQueryResultPhoto]
                    #p answer_inline
                    #p "______"
                    #p message
                    #p "==========="
                    begin
                    p Listener.bot.api.answer_inline_query(
                        inline_query_id: message.id,
                        results: answer_inline)
                    rescue Exception=>e
                        #p e
                    end
                end
            end
            module_function(
                :process
            )
        end
    end
end