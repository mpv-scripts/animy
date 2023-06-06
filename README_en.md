# What is this?

This is a script for mpv player, allowing you to watch videos right in mpv, instead of browser.

# How to install?

Clone this repo to `~/.config/mpv/scripts` (on Linux, or corresponding path to scripts directory for other OS'es, that uses another paths)

(currently, no distributions provide system-wide packages, and most probably never will)

# How to use?

```
$ mpv https://animy.org/releases/item/<title_name>/episode/<num>
```
or
```
$ mpv https://animy.org/compilations/item/vladyka-duhovnogo-mecha/episode/<num>
```


Unfortunately, there is too much work needed, to properly support playlists (and, moreover, there may be multiple layers of playlists, so for now only episode-URLs are supported)
And even in "compilation"'s' "episode" URLs, even if there is playlist in the player, it is not supported at the moment (but maybe it will be added in near commits).

Also, be noticed, that some titles have multiple "players" (in their web meaning), multiple formats (subtitles, voiceover) and even multiple voiceovers available.

Unfortunately, the engine used by animy.org is so much cursed, that it doesn't allow to easily handle that things.
So, you may sometimes need to perform some magic to make it work correctly.
For example, it can be set to play chinese version of the title.

