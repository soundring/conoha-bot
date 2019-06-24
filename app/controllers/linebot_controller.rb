class LinebotController < ApplicationController
    require 'line/bot'  # gem 'line-bot-api'
    require "json"
    require 'net/http'
    require 'uri'


    # このは---------------------------------------------------------------------------------
    


    def getNotification()
        # ConoHaユーザー名
        conoha_user = ENV["CONOHA_API_USER"]
        # ConoHaAPI ユーザーパスワード
        conoha_pass = ENV["CONOHA_API_KEY"]
        #tenantID
        conoha_tenant = ENV["CONOHA_API_TENANT"]
        #tenant名
        conoha_tenant_name = ENV["CONOHA_API_TENANT_NAME"]
        #トークン取得URL
        conoha_get_token_url = ENV["CONOHA_API_TOKEN_URL"]
        #告知一覧取得URL
        conoha_get_announce_url = ENV["CONOHA_API_ACCOUNT_URL"]

        token_uri = conoha_get_token_url
        username = conoha_user
        password = conoha_pass
        tenantName = conoha_tenant_name

        uri = URI.parse(token_uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri.request_uri)
        req["Content-Type"] = "application/json"
        req.body = '{ "auth": { "passwordCredentials": { "username": "'+ username +'", "password": "'+ password + '"}, "tenantName": "'+ tenantName +'" } }'
        res = http.request(req)
        json = JSON.parse(res.body)
        tokenId = json["access"]["token"]["id"]


        url = conoha_get_announce_url
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        #https.set_debug_output $stderr
        req = Net::HTTP::Get.new(uri.request_uri)
        req["Content-Type"] = "application/json"
        req["X-Auth-Token"] = tokenId
        res = https.request(req)

        if res.code == "200"
            json = JSON.parse(res.body)
            json["notifications"][0]["title"] + "\n" + json["notifications"][0]["contents"]
        else
            puts "できてないよ"
        end
    end
    # このは---------------------------------------------------------------------------------


  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)

    events.each { |event|
        #天気
        if event.message['text'].include?("天気教えて")
            tenki_url = 'http://api.openweathermap.org/data/2.5/forecast?q=tokyo,jp&lang=ja&appid='
            token = ENV["WEATHER_APIKEY"]

            uri = URI.parse(tenki_url + token)
            http = Net::HTTP.new(uri.host, uri.port)

            req = Net::HTTP::Get.new(uri.request_uri)
            res = http.request(req)
            json = JSON.parse(res.body)

            response = {
                type: 'text',
                text: json["list"][0]["weather"][0]["description"] + "だよ！"
            }
        elsif event.message['text'].include?("最新情報")
            response = {
                type: 'text',
                text: getNotification
            }
        elsif event.message['text'].include?("行ってきます")
            response = {
                type: 'text',
                text: "行ってらっしゃい♪"
            }
        elsif event.message['text'].include?("おはよう")
            response = {
                type: 'text',
                text: "おはよー！"
            }
        elsif event.message['text'].include?("こんにちは")
            response = {
                type: 'text',
                text: "こんにちはー！"
            }
        elsif event.message['text'].include?("こんばんは")
            response = {
                type: 'text',
                text: "こんばんはー"
            }
        elsif event.message['text'].include?("誕生日おめでとう")
            response = {
                type: 'text',
                text: "ありがとー！"
            }
        elsif event.message['text'].include?("梅宮")
            response = {
                type: 'text',
                text: "梅宮がなんだって？（不機嫌）"
            }
        elsif event.message['text'].include?("画像")
            image_url = "https://img.animatetimes.com/2019/03/5c95c0b2a83ed_8ad47016d98718910dedbdf61de7b0da.jpg"

            resoponse = {
                type: 'image',
                originalContentUrl: image_url,
                previewImageUrl: image_url
            }
        else
            response = {
                type: 'text',
                text: "ん？"
            }
        end

        case event
        when Line::Bot::Event::Message
            case event.type
            when Line::Bot::Event::MessageType::Text
            message = response
            client.reply_message(event['replyToken'], message)
            end
        end
    }

    head :ok
  end
end
