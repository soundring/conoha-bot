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
        conoha_get_announce_url = ENV["CONOHA_API_NEWS_URL"]

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


    # VM取得
    def getVmInfo
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
         #VM詳細取得URL
         conoha_get_vm_info_url = ENV["CONOHA_API_VM_GET_URL"]
 
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
         

        #  VM取得部分
         url = conoha_get_vm_info_url
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
             json["servers"][0]["metadata"]["instance_name_tag"] + "のサーバーの状態は" + json["servers"][0]["status"] + "だよ！" 
            
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
        if event.message['text'].include?("天気")
            tenki_url = 'http://api.openweathermap.org/data/2.5/forecast?q=tokyo,jp&lang=ja&appid='
            token = ENV["WEATHER_APIKEY"]

            uri = URI.parse(tenki_url + token)
            http = Net::HTTP.new(uri.host, uri.port)

            req = Net::HTTP::Get.new(uri.request_uri)
            res = http.request(req)
            json = JSON.parse(res.body)

            response = {
                type: 'text',
                text: "現在の東京の天気は" + json["list"][0]["weather"][0]["description"] + "だよ！"
            }
        elsif event.message['text'].include?("ニュース")
            response = {
                type: 'flex',
                altText: 'test',
                contents: {
                    type: 'bubble',
                    styles: {
                        header: {
                            backgroundColor: "#afeeee",
                        },
                        hero: {
                            separator: false,     separator: false,
                        }
                    },
                    header: {
                        type: 'box',
                        layout: 'vertical',
                        contents: [
                            {
                                type: 'text',
                                text: '最新ニュースだよ♪',
                                align: "center"
                            }
                        ]
                    },
                    body: {
                        type: 'box',
                        layout: 'vertical',
                        contents: [
                            {
                                type: 'text',
                                text: getNotification,
                                wrap: true,
                            }
                        ]
                    },
                    footer: {
                        type: 'box',
                        layout: 'vertical',
                        contents: [
                            {
                                type: 'button',
                                style: 'primary',
                                action: {
                                    type: 'uri',
                                    label: 'ニュース一覧へ',
                                    uri: 'https://www.conoha.jp/news/?btn_id=top_news'
                                }
                            }
                        ]
                    }
                }
            }
        elsif event.message['text'].include?("サーバーの状態")
            response = {
                type: 'text',
                text: getVmInfo 
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
        elsif event.message['text'].include?("あいさつ")
            response = {
                type: 'template',
                altText: '挨拶',
                template: {
                    type: 'buttons',
                    title: 'あいさつメニュー',
                    text: 'ん？何かな？',
                    actions: [
                        {
                            type: 'message',
                            label: 'おはよう',
                            text: 'おはよう'
                        },
                        {
                            type: 'message',
                            label: 'こんにちは',
                            text: 'こんにちは'
                        },
                        {
                            type: 'message',
                            label: 'こんばんは',
                            text: 'こんばんは'
                        },
                        {
                            type: 'message',
                            label: '行ってきます',
                            text: '行ってきます'
                        }
                    ]
                }  
            }
        elsif event.message['text'].include?("このはちゃんが好き")
            response = {
                type: 'text',
                text: "ありがとー！"
            }
        elsif event.message['text'].include?("梅宮")
            response = {
                type: 'text',
                text: "梅宮がなんだって？（不機嫌）"
            }
        elsif event.message['text'].include?("このはちゃん")
            response = {
                type: 'template',
                altText: '代替テキスト',
                template: {
                    text: '私のこと',
                    type: 'confirm',
                    actions: [
                        {
                            type: "message",
                            label: "好き",
                            text: "このはちゃんが好き"
                        },
                        {
                            type: "message",
                            label: "梅宮がいい",
                            text: "梅宮がいい"
                        }
                    ],
                }
            }
        elsif event.message['text'].include?("壁紙")
            n = 0
            images = [
                'https://conoha.mikumo.com/wp-content/themes/conohamikumo/images/wallpaper/2019_summer/1280_800.jpg',
                'https://conoha.mikumo.com/wp-content/themes/conohamikumo/images/wallpaper/2019_spring/1280_800.jpg',
                'https://conoha.mikumo.com/wp-content/themes/conohamikumo/images/wallpaper/2018_christmas/1280_800.jpg',
                'https://conoha.mikumo.com/wp-content/themes/conohamikumo/images/wallpaper/2018_winter/1280_800.jpg',
                'https://conoha.mikumo.com/wp-content/themes/conohamikumo/images/wallpaper/2018_halloween/1280_800.jpg',
                'https://conoha.mikumo.com/wp-content/themes/conohamikumo/images/wallpaper/2018_autumn/1280_800.jpg',
                'https://conoha.mikumo.com/wp-content/themes/conohamikumo/images/wallpaper/2018_yukata/1280_800.jpg',
                'https://conoha.mikumo.com/wp-content/themes/conohamikumo/images/wallpaper/2018_rain/1280_800.jpg',
                'https://conoha.mikumo.com/wp-content/themes/conohamikumo/images/wallpaper/2018_spring/1280_800.jpg'
            ]
            n = Random.rand(0 .. 8)
            response = {
                type: 'image',
                originalContentUrl: images[n],
                previewImageUrl: images[n]            
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
