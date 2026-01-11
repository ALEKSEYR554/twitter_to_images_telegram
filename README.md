Bot for sending images/gifs/videos from twitter directly to telegram if it satisfy file size in MB(AKA send by not blue mark user)

## Demonstration
<https://raw.githubusercontent.com/ALEKSEYR554/twitter_to_images_telegram/refs/heads/main/demo/demo.mp4>

## Credentials
By default all credentials are stored in [mac-shake.rb](library/mac-shake.rb)

API_KEY - Telegram Api Key from BotFather

ERROR_CHANNEL_ID - channel (user_id) to send errors to

ADMIN_LIST - Admin List who can use admin commands

WHITE_LIST_IDS - List of user ids who can use inline without subscribing to channel if enabled

CHANNEL_LINK - Channel nedded to subscribe to to disable channel link while using inline mod if enabled


## Add bot to channel
Give it permission to delete and send message. It will delete any `/https:\/\/(fxtwitter|twitter|x)\.com/` link, send request to
[FxTwiter](https://github.com/FixTweet/FxTwitter), fetch all media links and send to the same channel.

If added to comments chat it would send uncompressed versions (except videos and gifs)

## Enable inline mode in BotFather

Pass a twitter/x link and select nedded

## Admin commands
`/remove_cache` - remove all uncompressed links from queue

`/ping` - pong

`/send_latest_log` and `/send_other_logs` - sends latest log.log file to `ADMIN_LIST` dm, by default 3 log files 10mb each are maximum. Other logs are log.log.0 and log.log.1

Also you can send raw fxtwitter json responce for post instead of link

There is also whitelist option for inline mode oncomment `!Security::is_subscribe(message.from)` section in inline_query file and add `CHANNEL_LINK` to [mac-shake.rb](library/mac-shake.rb)
## Known bug(s)

Sometimes tweets with videos and images fail to upload in one post because video doesn't have audio but fxtwitter returns video/mp4
