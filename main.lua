-- luacheck: globals mp
-- local i=require"inspect"
local msg = require "mp.msg"

local function fetch(url,opts)
  local luacurl_available, cURL = pcall(require,'cURL')
  if luacurl_available then
    local buf={}
    local o = opts or {}
    -- local UA = "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
    local UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    local c = cURL.easy_init()
    local headers = {
      "Accept: */*",
      -- "Accept-Language: ru,en",
      -- "Accept-Charset: utf-8,cp1251,koi8-r,iso-8859-5,*",
      "Cache-Control: no-cache",
      -- "Origin: https://animy.org",
      ("Referer: %s"):format(o.ref or "https://animy.org/"),
    }
    c:setopt_httpheader(headers)
    c:setopt_followlocation(1)
    c:setopt_header(1)
    c:setopt_useragent(UA)
    c:setopt_cookiejar(o.cookie or "/tmp/mpv.animy.cookies")
    c:setopt_cookiefile(o.cookie or "/tmp/mpv.animy.cookies")
    c:setopt_url(url)
    c:setopt_writefunction(function(chunk) table.insert(buf,chunk); return true; end)
    c:perform()
    -- print(i(buf))
    return table.concat(buf)
  else
    msg.error"Sorry, I need Lua-cURL (https://github.com/Lua-cURL/Lua-cURLv3) for work."
    msg.error"Please, install it using system package manager or any other method"
    msg.error"The goal is that Lua interpreter that mpv was built with should be able to find it"
  end
end

local function animyCheck()
  local path = mp.get_property("path", "")
  -- local path = mp.get_property("stream-open-filename", "")
  if path:match("^(%a+://animy.org/.*)") then
    msg.verbose[[Hello! animy.org link detected.]]
    local o -- luacheck: ignore

    local req_o = {}
    for k,v in path:gmatch[=[%#%#%#([^%=%#]+)%=([^%#]+)]=] do
      req_o[k] = v
    end
    path=path:gsub("###.+$","")

    if path:match("[%?]") then
      msg.warn[[Link with paramaters detected. It seems, you're trying to set some settings (like player, voiceover or format)]] -- luacheck: ignore
      msg.warn[[Because of shitty-coded backend of animy.org, which uses non-standard headers, and proprietary cookies, this requires some additional handling]] -- luacheck: ignore
      msg.warn[[And even with it, it can still refuse work as expected]]
      local r = fetch(path, o):match[=[efresh: .+URL=([a-zA-Z0-9:/_+.-]+)]=]
      if not r then
        msg.error"Something gone wrong"
        os.exit(9)
      else
        -- o = { ref = path }
        -- local player_url = fetch(r, o):match([=[<meta property="og:video" content="([^"]+)"]=])
        msg.warn[[Paramaters should be applied now.]]
        msg.warn[[This fucking shit doesn't work as expected if we'll try re-fetch episode URL automatically in this mpv instance.]] -- luacheck: ignore
        msg.warn[[So, please, now *RE-RUN* mpv with *WITHOUT* "?param=value" part of URL (pass just episode URL itself)]] -- luacheck: ignore
        msg.warn[[Although, be noticed, that we just requested a page with settings, and just recieved cookies with corresponding settings.]] -- luacheck: ignore
        msg.warn[[But this fucking shit can still randomly return another player, another voiceover and even another format.]] -- luacheck: ignore
        msg.warn[[We just doing our best on trying to get this black box to work SOMEHOW, don't blame us if it doesn't work...]] -- luacheck: ignore
        mp.command[[quit]]
      end
    end

    local player_url = fetch(path, o):match([=[<meta property="og:video" content="([^"]+)"]=])
    if player_url then
      -- msg.info(player_url)
      if player_url:match"vk%.com" then
        msg.verbose[[Current selected player for this episode is "vk.com". Should be handled further by ytdl]]
        msg.verbose[[By the way, it is known to send tons of broken packets, so you may get tons of ffmpeg/demuxer spam]] -- luacheck: ignore
        mp.set_property("stream-open-filename", player_url)
      elseif player_url:match"youtube%.com" or player_url:match"youtu%.be" then
        msg.verbose[[Current selected player for this episode is "YouTube". Should be handled further by ytdl]]
        mp.set_property("stream-open-filename", player_url)
      elseif player_url:match"csst.online" then
        local q = {
          ["1080p"] = "",
          ["720p"] = "_720p",
          ["360p"] = "_360p",
        }

        local match_pattern = [=[https://[^,%[]*%d__PH__%.mp4]=] -- TODO: subtitles
        local ph = q[req_o.q] or "_720p"
        match_pattern = match_pattern:gsub("__PH__", ph)
        local vid_url = fetch(player_url, o):match(match_pattern)
        if vid_url then
          mp.set_property("stream-open-filename", vid_url)
          -- TODO: fill playlistwith neighbour episodes
        else
          msg.error[[Current player is AllVideo, but something gone wrong when we tried to get video URL. Please, report.]] -- luacheck: ignore
        end
      elseif
        player_url:match"^//anivod%.com"
          or
        player_url:match"^//aniqit%.com"
        -- player_url:match"^//ani...%.com/seria"
      then
        -- player_url=(player_url:gsub("^//","https://"))
        msg.error[[Looks like current selected player for this episode is "KODIK".]]
        msg.error[[Unfortunately, at the moment, it is unsupported by this plugin.]]
        msg.error[[Try to select another player (if available) by passing "?player=N" to the URL]]
        msg.error[[(see another available players buttons by opening URL in browser, and see the path of links that buttons have)]] -- luacheck: ignore
        os.exit(1)
      elseif player_url:match"^//player%.animy%.org" then
        -- player_url=(player_url:gsub("^//","https://"))
        msg.error[[Looks like current selected player for this episode is proprietary AniMy's one.]]
        msg.error[[Unfortunately, at the moment, it is unsupported by this plugin.]]
        msg.error[[Try to select another player (if available) by passing "?player=N" to the URL]]
        msg.error[[(see another available players buttons by opening URL in browser, and see the path of links that buttons have)]] -- luacheck: ignore
        os.exit(1)
      else
        msg.error[[Unknown player (don't know how to handle it). Please, report.]]
        msg.error(("Player URL is: %s"):format(player_url))
        os.exit(1)
      end
    end
    -- mp.set_property("ytdl_hook-exclude", 'animy')
  end
end

mp.add_hook("on_load",10, animyCheck)

