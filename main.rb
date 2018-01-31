require 'bundler/setup'
require 'yaml'
require 'mastodon'
require 'sanitize'

config = YAML.load_file("./key.yml")
debug = false

stream = Mastodon::Streaming::Client.new(
  base_url: "https://" + config["base_url"],
  bearer_token: config["access_token"])

rest = Mastodon::REST::Client.new(
  base_url: "https://" + config["base_url"],
  bearer_token: config["access_token"])

account = config["account"]

begin
  stream.user() do |toot|
    if toot.kind_of?(Mastodon::Notification) then
      if toot.type == "mention" then
        content = toot.status.content
        content.gsub!(/<br\s?\/?>/, "\n")
        content.gsub!("</p><p>", "\n\n")
        content = Sanitize.clean(content)
        p "@#{toot.status.account.acct}: #{content}" if debug
        if toot.status.visibility == "direct" then
          content.gsub!(Regexp.new("@#{account}", Regexp::IGNORECASE), "")
          p toot.status.attributes["spoiler_text"] if debug
          p content if debug
          rest.create_status(content, spoiler_text:toot.status.attributes["spoiler_text"])
        end
      end
    end
  end
rescue => e
  p "error"
  puts e
  retry
end
