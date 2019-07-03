class GetConoHaAPI
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
end