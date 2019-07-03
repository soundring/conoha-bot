class GetWeather
    def get_weather
        tenki_url = 'http://api.openweathermap.org/data/2.5/forecast?q=tokyo,jp&lang=ja&appid='
                    token = ENV["WEATHER_APIKEY"]

                    uri = URI.parse(tenki_url + token)
                    http = Net::HTTP.new(uri.host, uri.port)

                    req = Net::HTTP::Get.new(uri.request_uri)
                    res = http.request(req)
                    json = JSON.parse(res.body)
                    json["list"][0]["weather"][0]["description"] 
    end
end