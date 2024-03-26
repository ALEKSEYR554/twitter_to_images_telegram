Bot for sending images/gifs/videos from twitter directly to telegram if it satisfy file size in MB(AKA send by not blue mark user)

## Add bot to channel
Give it permission to delete and send message. It will delete any `/https:\/\/(fxtwitter|twitter|x|fixupx)\.com/` [code](https://github.com/ALEKSEYR554/twitter_to_images_telegram/blob/89d77d217c52e15eb3704c4b032061c04f9db6fa/modules/standart_messages.rb#L258C10-L258C60) link send request to
[FxTwiter](https://github.com/FixTweet/FxTwitter), fetch all media links and send to the same channel with it's uncompressed versions (except videos and gifs)


## Enable inlune mode in BotFather

Pass a twitter/x link and select nedded

## Known bug(s)

Sometimes tweets with videos and images fail to upload in one post because video doesn't have audio but fxtwitter returns video/mp4
