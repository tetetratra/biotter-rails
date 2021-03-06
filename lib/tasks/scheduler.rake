task :crawl => :environment do
  Exec.crawl
end

class Exec
  require 'digest/md5'
  SITE_URL = 'biotter.herokuapp.com'
  PARAMS = [
    :user_twitter_id,
    :user_screen_name,
    :user_name,
    :user_location,
    :user_description,
    :user_url,
    :user_profile_image_hash,
    :user_profile_banner_hash
  ]

  def self.crawl
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['BIOTTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['BIOTTER_CONSUMER_SECRET']
      config.access_token        = ENV['BIOTTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['BIOTTER_ACCESS_TOKEN_SECRET']
    end

    follower_profiles = client.followers.map(&:to_h).map do |follower|
      # ツイッター用に短縮されたURLを戻すため、URLの対応テーブルをつくる
      url_master = ((follower[:entities][:url] && follower[:entities][:url][:urls]).to_a + follower[:entities][:description][:urls])
                     .map { |url| [url[:url], url[:expanded_url]] }

      user_twitter_id         = follower[:id]
      user_screen_name        = follower[:screen_name]
      user_name               = follower[:name]
      user_location           = follower[:location]
      user_description        = follower[:description].then do |description|
        description.nil? ? nil : url_master.inject(description) { |new_description, (short_url, full_url)| new_description.gsub(short_url, full_url) }
      end
      user_url = follower[:url].then do |url|
        url.nil? ? nil : url_master.inject(url) { |new_url, (short_url, full_url)| new_url.gsub(short_url, full_url) }
      end
      user_profile_image      = fetch_profile_image(follower[:profile_image_url].gsub('_normal', '_200x200'))
      user_profile_banner     = fetch_profile_banner(follower[:profile_banner_url])

      {
        user_twitter_id: user_twitter_id,
        user_screen_name: user_screen_name,
        user_name: user_name,
        user_location: user_location,
        user_description: user_description,
        user_url: user_url,
        user_profile_image: user_profile_image,
        user_profile_banner: user_profile_banner,
        user_profile_image_hash: Digest::MD5.hexdigest(user_profile_image),
        user_profile_banner_hash: Digest::MD5.hexdigest(user_profile_banner)
      }
    rescue => e
      p e.full_message(highlight: false)
      next nil
    end.compact

    follower_profiles.each do |follower_profile|
      next unless self.new_follower_profile?(follower_profile)

      profile = Profile.new(**follower_profile.slice(*PARAMS))
      profile.user_profile_image.attach(io: StringIO.new(follower_profile[:user_profile_image]), filename: 'icon.png') if follower_profile[:user_profile_image]
      profile.user_profile_banner.attach(io: StringIO.new(follower_profile[:user_profile_banner]), filename: 'banner.png') if follower_profile[:user_profile_banner]
      profile.save

      safe_description = follower_profile[:user_description].gsub(/@|#|\*/, '●')
      tweet_str = "#{follower_profile[:user_name]}さん(#{follower_profile[:user_screen_name]})のプロフィールが更新されました!\n #{safe_description}".truncate(100) \
       + "\nhttps://#{SITE_URL}/?user_name=#{follower_profile[:user_screen_name]}"
      client.update(tweet_str) if Rails.env.production?
      p tweet_str if Rails.env.development?
    end
  end

  def self.fetch_profile_image(url)
    return nil if url.nil?

    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request['Upgrade-Insecure-Requests'] = '1'
    request['Sec-Fetch-Mode'] = 'navigate'
    request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'
    req_options = { use_ssl: uri.scheme == 'https' }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }
    body = response.body
    raise if body.include?('DOCTYPE html')

    body
  end

  def self.fetch_profile_banner(url)
    return nil if url.nil?

    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request['Upgrade-Insecure-Requests'] = '1'
    request['Sec-Fetch-Mode'] = 'navigate'
    request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'
    req_options = { use_ssl: uri.scheme == 'https' }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }
    body = response.body
    raise if body.include?('DOCTYPE html')

    body
  end

  def self.new_follower_profile?(follower_profile)
    latest_profile = Profile.where(user_twitter_id: follower_profile[:user_twitter_id]).order('created_at DESC').first
    return true if latest_profile.nil?

    follower_profile.slice(*PARAMS) != latest_profile.attributes.symbolize_keys.slice(*PARAMS)
  end
end

task :add_image_hash => :environment do
  require 'digest/md5'
  Profile.all.find_each do |profile|
    if profile.user_profile_image && img = profile.user_profile_image.try(:download)
      hash = Digest::MD5.hexdigest(img)
      profile.update(user_profile_image_hash: hash)
    end

    if profile.user_profile_banner && img = profile.user_profile_banner.try(:download)
      hash = Digest::MD5.hexdigest(img)
      profile.update(user_profile_banner_hash: hash)
    end
  end
end

=begin
# 旧appから画像をクローリング。使い捨てスクリプト
task :import_image_from_oldapp => :environment do
  Profile.all.reverse.each do |profile|
    sleep 0.5
    uri = URI.parse("https://biotter.tetetratra.net/profile_image/#{profile.id}")
    request = Net::HTTP::Get.new(uri)
    req_options = { use_ssl: uri.scheme == "https" }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    next unless response.code == '200'

    profile.user_profile_image.attach(io: StringIO.new(response.body), filename: 'icon.png')
    profile.save
  end
end

task :import_banner_from_oldapp => :environment do
  Profile.all.reverse.each do |profile|
    sleep 0.5
    uri = URI.parse("https://biotter.tetetratra.net/profile_banner/#{profile.id}")
    request = Net::HTTP::Get.new(uri)
    req_options = { use_ssl: uri.scheme == "https" }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    next unless response.code == '200'

    profile.user_profile_banner.attach(io: StringIO.new(response.body), filename: 'banner.png')
    profile.save
  end
end
=end
