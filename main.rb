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
          content.gsub!(Regexp.new("@#{account}", Regexp::IGNORECASE), "")
          p "画像あり" if !(toot.status.media_attachments == [])
          imgs = []
          o_imgt = []
          toot.status.media_attachments.each {|ml|
            imgs << ml.id
            o_imgt << ml.attributes["text_url"]
            open(ml.id, "wb") {|mid|
              open(ml.url) {|mu|
                mid.write(mu.read)
                p "saved: #{ml.id}"
              }
            }
          }
          uml = []
          n_imgt = []
          imgs.each {|u|
            media = rest.upload_media(u)
            uml << media.id
            n_imgt << media.attributes["text_url"]
            p "uploaded: #{u}"
          }
          if !(toot.status.media_attachments == []) && !(o_imgt.include?(nil)) then
            imgt = [o_imgt, n_imgt].transpose
            imgt = Hash[*imgt.flatten]
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
    end
  end
rescue => e
  p "error"
  puts e
  retry
end
