class LinebotController < ApplicationController
    require 'line/bot'  # gem 'line-bot-api'
    require "json"
    require 'net/http'
    require 'uri'
    require_relative '../modules/weather/get_weather'
    require_relative '../modules/conoha/get_notification'
    require_relative '../modules/conoha/get_vm_info'

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
        if event.message['text'].include?("天気")
            weather = GetWeather.new
            response = {
                type: 'text',
                text: "現在の東京の天気は" + weather.get_weather + "だよ！"
            }
        elsif event.message['text'].include?("ニュース")
            get_notification = GetConoHaAPI.new
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
                            separator: false, 
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
                                text: get_notification.getNotification,
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
            vm_info = GetVmInfo.new
            response = {
                type: 'text',
                text: vm_info.getVmInfo
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
                            text: "梅宮さんがいい"
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
        elsif event.message['text'].include?('どこにいるの？')
            response = {
                type: 'location',
                title: "ここにいるよ～",
                address: "桜丘町26-1 (セルリアンタワー) 渋谷区, 東京都 150-8512 日本",
                latitude: 35.65610180502175,
                longitude: 139.69945200061724,
            }
        elsif event.message['text'].include?('イメージ')
            response = {
                type: 'template',
                altText: 'イメージ一覧',
                template: {
                    type: 'carousel',
                    actions: [],
                    columns: [
                        {
                            thumbnailImageUrl: 'https://user-images.githubusercontent.com/14822782/60555064-b54d7e80-9d75-11e9-8eb7-f16a9a835fb6.png',
                            title: 'CentOS',
                            text: " ",
                            actions: [
                                {
                                    type: 'message',
                                    label: 'CentOS',
                                    text: "CentOS"
                                }
                            ]
                        },
                        {
                            thumbnailImageUrl: 'https://user-images.githubusercontent.com/14822782/60555092-e0d06900-9d75-11e9-986c-de670f42c292.png',
                            title: 'Ubuntu',
                            text: ' ',
                            actions: [
                                {
                                    type: 'message',
                                    label: 'Ubuntu',
                                    text: 'Ubuntu'
                                }
                            ]
                        },
                        {
                            thumbnailImageUrl: 'https://user-images.githubusercontent.com/14822782/60554837-5c311b00-9d74-11e9-8ac0-4eac2994571f.png',
                            title: 'Debian',
                            text: ' ',
                            actions: [
                                {
                                    type: 'message',
                                    label: 'Debian',
                                    text: 'Debian'
                                }
                            ]
                        },
                        {
                            thumbnailImageUrl: 'https://user-images.githubusercontent.com/14822782/60555122-12493480-9d76-11e9-8801-2dc7e14f74a9.png',
                            title: 'FreeBSD',
                            text: ' ',
                            actions: [
                                {
                                    type: 'message',
                                    label: 'FreeBSD',
                                    text: 'FreeBSD'
                                }
                            ]
                        },
                        {
                            thumbnailImageUrl: 'https://user-images.githubusercontent.com/14822782/60554934-df527100-9d74-11e9-8a1c-b35715da330a.png',
                            title: 'Fedora',
                            text: ' ',
                            actions: [
                                {
                                    type: 'message',
                                    label: 'Fedora',
                                    text: 'Fedora'
                                }
                            ]
                        },
                        {
                            thumbnailImageUrl: 'https://user-images.githubusercontent.com/14822782/60554912-c053df00-9d74-11e9-9846-c6bc14dcebe5.png',
                            title: 'openSUSE',
                            text: ' ',
                            actions: [
                                {
                                    type: 'message',
                                    label: 'openSUSE',
                                    text: 'openSUSE'
                                }
                            ]
                        }
                    ]
                }
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
            when Line::Bot::Event::MessageType::Location
                message =  {
                    type: 'text',
                    text: 'aaaaaaa'
                }
                client.reply_message(event['replyToken'],message)
            end
        end
    }

    head :ok
  end
end
