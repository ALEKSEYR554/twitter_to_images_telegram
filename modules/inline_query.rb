class FishSocket
    module Listener
      # This module assigned to processing all InlineQuery requests
        module InlineQuery
            def process
                
                #p "inline=#{Listener.message}" 



                #EXAMPLE
                eXAMPLE_code='''
                if not Codes.is_in_whitelist?(Listener.message.from)
                    begin
                    Listener.bot.api.answer_inline_query(
                            inline_query_id: Listener.message.id,
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
                #p Listener.message.query
                case Listener.message.query
                when /https:\/\/(fxtwitter|twitter|x|fixupx)\.com/#.match?("#{Listener.message}")#.include? "https://twitter.com" or Listener.message.include? "https://x.com"
                    begin
                    response=StandartMessages.get_fxtwitter_response("#{Listener.message}")[0]
                    rescue Exception=>e
                        return
                    end
                    #p "???"
                    #p "---"
                    #p response
                    #p "---"
                    if response=="IT IS TEXT"
                        begin
                        Listener.bot.api.answer_inline_query(
                                inline_query_id: Listener.message.id,
                                results: [Telegram::Bot::Types::InlineQueryResultArticle.new(
                                    id: "0",
                                    title: "There is no media found",
                                    input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(message_text: "There is no media found")
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
                        #capt="#{i+1}/#{response['tweet']["media"]['all'].length}\n<a href=\"#{Listener.message.query}\">Twitter</a>"
                        capt="<a href=\"#{Listener.message.query}\">Twitter</a>"
                        if !Security::is_subscribe(Listener.message.from)
                            #p "unsub"
                            capt+="\n#{TelegramConstants::CHANNEL_LINK}\nSubscribe to disable it" unless Codes.is_in_whitelist?(Listener.message.from)
                        end
                        
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
                                    thumb_url:media["thumbnail_url"],
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
                                    thumb_url:media["thumbnail_url"]
                                    )
                            when "photo"
                                Telegram::Bot::Types::InlineQueryResultPhoto.new(
                                    id:"#{i}",
                                    photo_url:"#{media["url"]}:orig",
                                    photo_width:media["width"],
                                    caption:capt,
                                    parse_mode:"HTML",
                                    photo_height:media["height"],
                                    thumb_url:"#{media["url"]}:orig"
                                    )
                        end
                    end
                    #if response['tweet']["media"].has_key? "mosaic"
                    #    answer_inline<<
                    #end
                    #answer_inline=[Telegram::Bot::Types::InlineQueryResultPhoto]
                    #p answer_inline
                    #p "______"
                    #p Listener.message
                    #p "==========="
                    begin
                    p Listener.bot.api.answer_inline_query(
                        inline_query_id: Listener.message.id,
                        is_personal: true,
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