require 'bundler/setup'
require 'yaml'
require 'mastodon'
require 'sanitize'
require 'open-uri'

config = YAML.load_file("./key.yml")
debug = false

stream = Mastodon::Streaming::Client.new(
  base_url: "https://" + config["base_url"],
  bearer_token: config["access_token"])

rest = Mastodon::REST::Client.new(
  base_url: "https://" + config["base_url"],
  bearer_token: config["access_token"])

account = rest.verify_credentials().acct

begin
  stream.user() do |toot|
    if toot.kind_of?(Mastodon::Notification) then
      if toot.type == "mention" then
        content = toot.status.content
        content.gsub!(/<br\s?\/?>/, "\n")
        content.gsub!("</p><p>", "\n\n")
        content = Sanitize.clean(content).strip
        p "@#{toot.status.account.acct}: #{content}" if debug
        if toot.status.visibility == "direct" then
          if content.start_with?(Regexp.new("^@#{account}\s+bt\s", Regexp::IGNORECASE)) then
            uris = content.gsub(Regexp.new("^@#{account}\s+bt\s", Regexp::IGNORECASE), "").split(" ")
            uris.each {|uri|
              result = rest.search(uri).attributes["statuses"][0]
              if !result.nil? then
                if result["visibility"] != "private" then
                  rest.reblog(result["id"])
                end
              end
            }
          elsif content.start_with?(Regexp.new("^@#{account}\s+fav\s", Regexp::IGNORECASE)) then
            uris = content.gsub(Regexp.new("^@#{account}\s+fav\s", Regexp::IGNORECASE), "").split(" ")
            uris.each {|uri|
              result = rest.search(uri).attributes["statuses"][0]
              if !result.nil? then
                rest.favourite(result["id"])
              end
            }
          else
            content.gsub!(Regexp.new("^@#{account}", Regexp::IGNORECASE), "")
            p "画像あり" if !(toot.status.media_attachments == []) && debug
            imgs = []
            o_imgt = []
            toot.status.media_attachments.each {|ml|
              imgs << ml.id
              p ml.attributes["text_url"] if debug
              o_imgt << ml.attributes["text_url"]
              open(ml.id, "wb") {|mid|
                open(ml.url) {|mu|
                  mid.write(mu.read)
                  p "saved: #{ml.id}" if debug
                }
              }
            }
            uml = []
            n_imgt = []
            imgs.each {|u|
              media = rest.upload_media(u)
              uml << media.id
              n_imgt << media.attributes["text_url"]
              p "uploaded: #{u}" if debug
            }
            p o_imgt if debug
            p n_imgt if debug
            if !(toot.status.media_attachments == []) && !(o_imgt.include?(nil)) then
              imgt = [o_imgt, n_imgt].transpose
              imgt = Hash[*imgt.flatten]
              p imgt if debug
              content = content.gsub(Regexp.union(o_imgt), imgt)
            end
            content = 0x200B.chr("UTF-8") if content.empty? && !(uml.empty?)
            p "spoiler text: #{toot.status.attributes["spoiler_text"]}" if debug
            p "content: #{content}" if debug
            p "media: #{uml}" if debug
            p "sensitive?: #{toot.status.attributes["sensitive"]}" if debug
            rest.create_status(content, sensitive: toot.status.attributes["sensitive"], spoiler_text: toot.status.attributes["spoiler_text"], media_ids: uml)
          end
        end
      elsif toot.type == "follow" then
        rest.follow(toot.account.id)
        p "follow: #{toot.account.acct}" if debug
      end
    end
  end
rescue => e
  p "error"
  puts e
  retry
end
