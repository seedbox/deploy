<img src="https://raw.githubusercontent.com/seedbox/deploy/imgs/seedbox.png">

# One line seedbox installer:

```sh
wget -qO- https://raw.githubusercontent.com/seedbox/deploy/master/install.sh | sh -s \
USERNAME PASSWORD SERVER_IP BANDWITH_LIMIT
```

**Applications installed:**
- Transmission
- CouchPotato
- SickRage (a SickBeard variant)
- Headphones
- A homepage / maintanance page

**Custom homepage** ([limited demo](http://seedbox.github.io/deploy/)) <br>
Streaming: Stream your media directly from you seedbox if you have enough bandwith.
<br>
Management: Monitor your bandwith and disk usage, turn services on and off, change your password, generate new certifiates, etc.

**Password protected HTTPS access** <br>
Everything is password protected and only accessible through an encrypted HTTPS connection. (nginx reverse proxy)

**Ready out of the box** <br>
The installer adds all the necessary folders and applies some sensible defaults so you can use your seedbox as soon as the installer finishes.

**Maintenance free transmission** <br>
Downloads are automatically processed and sorted by type. Files that have completed seeding are scheduled to be removed from transmission every hour (without deleted the downloaded files) so you don't have to even think about it.

**IP Logging** <br>
As much IP logging is removed from the server as is possible so you can sleep better at night. (But please don't think this means your seedbox is an invincible bastion on anonimity)


## Installation Details:
This installer was built for ubuntu machines and has been tested with Ubuntu 14.04.

SSH into your fresh server and run this command **as root**, replacing the values with your own:

```sh
wget -qO- https://raw.githubusercontent.com/seedbox/deploy/master/install.sh | sh -s \
USERNAME PASSWORD SERVER_IP BANDWITH_LIMIT
```

The `USERNAME` and `PASSWORD` values will be what you want to use to password protect all your web applications, like Transmission and CouchPotato.

The `SERVER_IP` can either be your server's public IP address, or a domain name you will use.  The installer uses this to generate a self signed SSL certificate for the web applications.

The `BANDWIDH_LIMIT` is your monthly bandwith limit, in GB, for your server. The installer uses this so you can track your usage on your maintenance page.

That's it! The installer will update and install everything. This will take some time, so get ready to find something else to do while it completes. You'll know it's done when you see: "Chef Client finished, 130 resources updated."

## What you need to know:

**How to access your applications** <br>
```
Homepage:                 https://SERVER_IP/
CouchPotato:              https://SERVER_IP/movies
SickRage:                 https://SERVER_IP/tv
Headphones:               https://SERVER_IP/music
Transmission:             https://SERVER_IP/downloads
```

**How to access your files** <br>
You can use an FTP program like [filezilla](https://filezilla-project.org/) to get your files, or you can access them over the web from these password protected locations:
```
movies:                   https://SERVER_IP/stream/movies
tv:                       https://SERVER_IP/stream/tv
music:                    https://SERVER_IP/stream/music
other downloads:          https://SERVER_IP/stream/other
```

**Where files are stored on the server** <br>
```
/home/downloads/incomplete  <= Where downloads are kept before finishing
/home/downloads/processing  <= Where downloads from couchpotato, sickbeard
                               and headphones are kept before finishing

/home/movies                <= Completed movies from couchpotato
/home/music                 <= Completed music from headphones
/home/tv                    <= Completed tv shows from sickrage
/home/other                 <= All other completed downloads
```

**Installing self signed certificates** <br>
The first time you access your server from a browser, you'll see something like [this](https://raw.githubusercontent.com/seedbox/deploy/imgs/chrome_untrusted.png) indicating that the certificate you are using isn't recognized because you made it yourself. This is totally fine, since you are the only one using it.

You can tell your computer / phone you trust the certificate and it will stop giving you warnings. You can download the certificate from your seedbox's homepage.

**Streaming media** <br>
Browsers are limited in what types of videos they can play.  If you have VLC installed, the web plugin will be able to play anything your browser cannot (as long as your internet connection is fast enough or course).

_Be sure to have you self signed certificate installed though_ (see above), or VLC might freak out and not play your videos.

**Handy chrome extension** <br>
Browsers will try to remember your passwords for you so you don't have to enter them every time, but as soon as you restart, they forget. I use [this extension](https://chrome.google.com/webstore/detail/multipass-for-http-basic/enhldmjbphoeibbpdhmjkchohnidgnah?hl=en) in chrome to auto-fill my username/password.


## Possible Issues
I've tested the installer pretty heavily, but here are some issues that might come up:

- After installation, couchpotato might not have started. You can start it manually from your server's homepage
- If sickrage gives you a 'gateway error' after installation, just restart it manually from your server's homepage
- If your VPS randomly shuts down during installation, just reboot it and run the command again. (rare, sometimes happened to me on cheap VPS's)



## Why this installer?
Building your own seedbox is cheaper than paying for one, but configuring these applications can be time consuming. By using an installer, seedboxes on cheap VPS's can be seen as disposable resources rather than time commitments.

With an easy installer you can set up a new box every year on your cheap VPS du jour, or make one for a friend without breaking a sweat.

And if you break some configuration one day and have a hard time fixing it? No prob, just nuke the box and start again. You dig?