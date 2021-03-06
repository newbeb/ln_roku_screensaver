
Function init()
    m.top.backgroundColor = "0x662d91FF" '#662d91
    m.top.backgroundURI = ""

    m.TempLabel = m.top.findNode("temperature_label")
    m.DateLabel = m.top.findNode("date_label")
    m.TimeLabel = m.top.findNode("time_label")
    m.Background = m.top.findNode("background")
    ' m.Background.setFocus(true)

    m.global.observeField("Weather", "updateWeather")
    m.global.observeField("BackgroundUri", "updateBackground")

    m.Timer = m.top.findNode("secondTimer")
    m.Timer.control = "start"
    m.Timer.ObserveField("fire", "updateDate")

    m.top.setFocus(true) ' Set focus so we can capture events

end Function

function onKeyEvent(key as String, press as Boolean) as Boolean
    'print "Keyboard Event " + key
    if( press )
        payload = { "type": "keyPress", "key": key, "press": "true"}
        m.top.setField("keyPress", payload)
    else
        payload = { "type": "keyPress", "key": key, "press": "false" }
        m.top.setField("keyPress", payload)       
    end if
    return true
end function

'Date/Time functions
Function getDay()
    months = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
    ]

    today = CreateObject("roDateTime")
    today.ToLocalTime()

    day = today.GetWeekday()
    month = today.GetMonth()
    date = today.GetDayOfMonth()

    if(date > 3 and date < 21)
        suffix = "th"
    else if date MOD 10 = 1
        suffix = "st"
    else if date MOD 10 = 2
        suffix = "nd"
    else if date MOD 10 = 3
        suffix = "rd"
    else
        suffix = "th"
    end if

    return day + ", " + months[month-1] + " " + date.ToStr() + suffix
end Function

Function getTime()
    now = CreateObject("roDateTime")
    now.ToLocalTime()

    hour = now.GetHours()

    minutes = now.GetMinutes().ToStr()
    minutes = Right("0"+minutes, 2)

    if hour = 0
        hour = 12
        AmPm = " am"
    else if hour = 12
        AmPm = " pm"
    else if hour > 12
        hour = hour - 12
        AmPm = " pm"
    else 
        AmPm = " am"
    end if

    return hour.ToStr() + ":" + minutes + AmPm
end Function

function updateDate()
    m.DateLabel.text = getDay()
    m.TimeLabel.text = getTime()
end Function

Function updateWeather()
    if(m.global.Weather <> invalid)
        temperature = Int((m.global.Weather.main.temp - 273.15) * 1.8 + 32)
        m.TempLabel.text = temperature.ToStr() + "° and " + m.global.Weather.weather[0].description
    end if
end Function

'Background functions
Function updateBackground()
    if(m.global.BackgroundUri <> invalId)
        m.Background.callFunc("changeImage", m.global.BackgroundUri)
    end if
end Function