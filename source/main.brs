Function RunScreenSaver(params as Object) as Object 'This function is required for screensavers. It acts as a main method for screensavers
    main()
End Function

sub main()
    m.config = ReadAsciiFile("pkg:/config.json")
    m.config = ParseJSON(m.config)

    m.pendingXfers = {}

    screen = createObject("roSGScreen") 'Creates screen to display screensaver

    port = createObject("roMessagePort") 'Port to listen to events on screen
    screen.setMessagePort(port)

    ' Figure out our location
    m.zip = getZip()

    m.global = screen.getGlobalNode()
    m.global.AddFields({"BackgroundUri": "", "Weather": {}})

    scene = screen.createScene("UnsplashScreensaver") 'Creates scene to display on screen. Scene name (AnimatedScreensaver) must match ID of XML Scene Component
    screen.show()

    'https://community.roku.com/t5/Roku-Developer-Program/sending-info-from-scene-graph-to-main-thread/m-p/420478/highlight/true#M29140
    scene.observeField("keyPress", port)

    ' Load our data for the first time
    m.BackgroundUris = CreateObject("roList")
    m.global.BackgroundUri = getBackground()
    m.global.Weather = getWeather()

    print initializeDeviceAuthorizationConfig()
    print requestDeviceAuthorization(m.config.google)

    'counter = 0
    weatherCounter = 0
    switchBackgroundCounter = 0
    while(true) 'Uses message port to listen if channel is closed
        msg = wait(1, port)

        weatherCounter++
        switchBackgroundCounter++

        if (msg <> invalid)
            'print "Message " + type(msg)
            msgType = type(msg)
            if msgType = "roSGScreenEvent"
                if msg.isScreenClosed() then return ' Close things out if we close the screen
            else if msgType = "roSGNodeEvent"
                if msg.getField() = "keyPress"
                    keyEvent = msg.GetData()
                    print "Main handler " + keyEvent.key + " " + keyEvent.press

                    if keyEvent.press = "true"
                        if keyEvent.key = "right" or keyEvent.key = "fastforward"
                            m.global.BackgroundUri = getBackground()
                        end if
                    else
                        'print "Released"
                    end if
                end if
            end if
        end if

        ' Swap background
        if switchBackgroundCounter > 60000 ' 1 minute
            m.global.BackgroundUri = getBackground()
            switchBackgroundCounter = 0
        end if

        ' Update weather
        if weatherCounter > 1800000 ' 30 minutes
            m.global.Weather = getWeather()
            weatherCounter = 0
        end if

    end while
end sub


Function getBackground()

    if(m.BackgroundUris.Count() < 2)
        backgrounds = loadBackgrounds()
        while(backgrounds.IsNext())
            item = backgrounds.Next()
            m.BackgroundUris.AddTail(item)
        end while
    end if

    background = m.BackgroundUris.RemoveHead()
    return background.urls.regular

End Function

function loadBackgrounds()
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl("https://api.unsplash.com/photos/random?orientation=landscape&featured=true&count=10")
    request.AddHeader("Authorization", "Client-ID " + m.config.unsplash_api_key)
    response = request.GetToString()

    print "Fetched Backgrounds"

    if( response <> "")
        json = ParseJSON(response)

        if(json <> invalid)
            return json
        else
            return invalid
        end if
    else
        return invalid
    end if
end Function

Function getZip()
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl("http://api.ipstack.com/check?access_key="+m.config.ipstack_api_key)
    response = request.GetToString()

    print "Fetched Location"

    if(response <> "")
        json = ParseJSON(response)

        if(json <> invalid)
            return json.zip
        else
            return invalid
        end if
    else
        return invalid
    end if
end Function

'Weather functions
Function getWeather()
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl("https://api.openweathermap.org/data/2.5/weather?zip="+m.zip+"&APPID="+m.config.openweathermap_api_key)
    response = request.GetToString()

    print "Fetched Weather"

    if(response <> "")
        json = ParseJSON(response)

        if(json <> invalid)
            return json
        else
            return invalid
        end if
    else
        return invalid
    end if
end Function