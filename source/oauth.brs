' https://developer.roku.com/docs/developer-program/authentication/on-device-authentication.md
' Create Registry
'     reg_sec = CreateObject("roRegistrySection", <your_registry_section>")
' read
'     access_token_value = reg_sec.read("access_token_key_name")
' write
'    reg_sec.write("access_token_key_name", "access_token_value")
'    reg_sec.flush()
'
 Function initializeDeviceAuthorizationConfig() as Boolean
    ' https://accounts.google.com/.well-known/openid-configuration
    ' device_authorization_endpoint

    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl("https://accounts.google.com/.well-known/openid-configuration")
    response = request.GetToString()

    if( response <> "")
        json = ParseJSON(response)

        if(json <> invalid)
            m.token_endpoint = json.token_endpoint
            m.device_authorization_endpoint = json.device_authorization_endpoint
            return true
        end if
    end if

    return false
 End Function


Function requestDeviceAuthorization(config)

    print m.token_endpoint
    print m.device_authorization_endpoint

    clientId = config.ClientId

    print clientId

    eventPort = createObject("roMessagePort")
    request = CreateObject("roUrlTransfer")
    request.setMessagePort(eventPort)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    ' POST /device/code HTTP/1.1
    ' Host: oauth2.googleapis.com
    ' Content-Type: application/x-www-form-urlencoded
    request.SetUrl(m.device_authorization_endpoint)
    ' request.SetRequest("POST")
    request.AddHeader("Content-Type", "application/x-www-form-urlencoded")

    ' client_id=client_id&scope=email%20profile
    payload = "client_id=" + clientId + "&scope=email%20profile"

    ' https://developer.roku.com/docs/references/brightscript/interfaces/ifurltransfer.md
    if request.AsyncPostFromString(payload) ' TODO: Consider Async methods here...
        response = eventPort.waitMessage(0)
        if type(response) = "roUrlEvent" 
            if response.GetResponseCode() = 200
                return response
            else
                print response.GetResponseCode().ToStr() + " " + response.GetFailureReason()
            end if
        else
            print type(response)
        end if
    end if

    return invalid

    ' {
    '     "device_code": "AH-1Ng3zjQ0JTN18mv3pi_ET4-Xqsw8rApHG7Z9bSqs1YYlhSFTuT9KHK-xQokl4wAWXwPsc4-Y0BOncd--nq4CCKxjXoNNjnw",
    '     "user_code": "NTZV-DZML",
    '     "expires_in": 1800,
    '     "interval": 5,
    '     "verification_url": "https://www.google.com/device"
    ' }
End Function

Function awaitDeviceAuthorization(config)
    ' POST /token HTTP/1.1
    ' Host: oauth2.googleapis.com
    ' Content-Type: application/x-www-form-urlencoded

    ' client_id=client_id&
    ' client_secret=client_secret&
    ' device_code=device_code&
    ' grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Adevice_code
End Function


' sub authSignature() as string

'     key = m.oauth_consumer_key_secret.EncodeUriComponent() + "&" + m.oauth_token_secret.EncodeUriComponent()

'     url = "https://d-cmwnext.movetv.com/cmw/v1/client/jwt"
'     oauth_consumer_key = "oauth_consumer_key=" + m.oauth_consumer_key
'     oauth_nonce = "oauth_nonce=" + m.nonce
'     oauth_signature_method = "oauth_signature_method=HMAC-SHA1"
'     oauth_timestamp = "oauth_timestamp=" + m.timeStampSeconds.toStr()
'     oauth_token = "oauth_token=" + m.oauth_token
'     oauth_version = "1.0"

'     params = oauth_consumer_key + "&" + oauth_nonce + "&" + oauth_signature_method + "&" + oauth_timestamp + "&" + oauth_token + "&" + oauth_version

'     base = "POST&" + url.EncodeUriComponent() + "&" + params.EncodeUriComponent()

'     ? "//// key: "; key
'     ? "//// incode url: "; url.EncodeUriComponent()
'     ? "//// incode params: "; params.EncodeUriComponent()
'     ? "//// base: "; base

'     hmac = CreateObject("roHMAC")
'     signature_key = CreateObject("roByteArray")
'     signature_key.fromAsciiString(key)
'     if hmac.setup("sha1", signature_key) = 0
'         message = CreateObject("roByteArray")
'         message.fromAsciiString(base)
'         result = hmac.process(message)
'         return result.toBase64String()
'     else
'         return ""
'     end if
' end sub
