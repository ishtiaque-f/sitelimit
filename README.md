# sitelimit

A tiny, root-enforced daily time limit for distracting sites on Linux. No browser extension to disable.

It watches your **active window**, counts the seconds spent on configured sites (Facebook, Instagram, WhatsApp by default), and when the daily limit is hit it **blocks the domains via `/etc/hosts`** and closes the matching windows. Counters reset at midnight.

## How it works

1. Every second, reads the focused window's title (`xdotool`).
2. If the title matches a site, adds 1 second to that site's counter — any app counts (browser, web app, or native).
3. At the limit, appends `0.0.0.0 <domain> #sitelimit-<site>` lines to `/etc/hosts`, flushes DNS cache, and closes matching windows (`wmctrl`).
4. On a new day, counters reset and the `#sitelimit` lines are removed.

Runs as a systemd service, so it starts at boot and cannot be killed without root.

## Requirements

- Linux with systemd and an X11 session (i3, XFCE, etc.). Wayland is not supported (`xdotool`/`wmctrl` need X11).
- `xdotool`, `wmctrl`, `bash`, `coreutils`

```
sudo apt install xdotool wmctrl
```

## Install

```
git clone https://github.com/ishtiaque-f/sitelimit.git
cd sitelimit
sudo ./install.sh
```

Uninstall (also unblocks all sites):

```
sudo ./uninstall.sh
```

## Usage

```
sitelimit status    # time used / limit per site
sudo sitelimit reset  # reset today's counters and unblock
```

Example:

```
fb   02:10 / 20:00
ig   15:30 / 20:00
wa   00:00 / 20:00
```

## Configuration

Edit `/etc/sitelimit.conf`, then `sudo systemctl restart sitelimit`.

```bash
USER_NAME=penguin          # owner of the X session
LIMIT=1200                 # seconds per site per day

# window-title regex per site
declare -A RE=( [fb]="Facebook|Messenger" [ig]="Instagram" [wa]="WhatsApp" )

# domains blocked per site when the limit is reached
declare -A DOMS=(
  [fb]="facebook.com www.facebook.com m.facebook.com messenger.com www.messenger.com"
  [ig]="instagram.com www.instagram.com"
  [wa]="web.whatsapp.com whatsapp.com www.whatsapp.com"
)
```

### Add a site

Add one entry to **both** arrays under the same short key. Example for YouTube:

```bash
declare -A RE=( [fb]="Facebook|Messenger" [ig]="Instagram" [wa]="WhatsApp" [yt]="YouTube" )

declare -A DOMS=(
  ...
  [yt]="youtube.com www.youtube.com m.youtube.com"
)
```

Or append it with one command:

```
sudo sed -i 's/\[wa\]="WhatsApp"/[wa]="WhatsApp" [yt]="YouTube"/' /etc/sitelimit.conf
```

(Then add the `[yt]=...` line inside `DOMS` by hand.)

Restart to apply:

```
sudo systemctl restart sitelimit
```

Tips:
- The `RE` value is a regex matched against the focused window title. Check what the title contains with `xdotool getactivewindow getwindowname`.
- List every domain variant (`www.`, `m.`, etc.) in `DOMS`, otherwise some will stay reachable after the limit.

### Remove a site

1. Delete its entry from **both** `RE` and `DOMS` in `/etc/sitelimit.conf`.
2. Unblock it and clear counters, then restart:

```
sudo sitelimit reset
sudo systemctl restart sitelimit
```

Optional: remove the leftover counter file, e.g. `sudo rm /var/lib/sitelimit/yt`.

### Change the limit

Edit `LIMIT` (seconds). One limit applies to every site. Example: 30 minutes is `LIMIT=1800`.

## Files

| Path | Purpose |
|---|---|
| `/usr/local/bin/sitelimit-daemon` | The counting loop |
| `/usr/local/bin/sitelimit` | CLI (`status`, `reset`) |
| `/etc/sitelimit.conf` | Settings |
| `/etc/systemd/system/sitelimit.service` | Service unit |
| `/var/lib/sitelimit/` | Daily counters |

## Troubleshooting

- **Counters not rising:** check the title the daemon sees. Focus the window and run `xdotool getactivewindow getwindowname`. The title must match the `RE` regex.
- **Check logs:** `journalctl -u sitelimit -n 30 --no-pager`
- **Still opens after block:** the browser may use cached DNS or DNS-over-HTTPS. Disable DoH in the browser, or restart it.

## Limitations

- Easy to bypass by someone with root. This is a self-discipline tool, not parental control.
- Counts only the focused window; background tabs are not counted.
- Matches by window title, so a page title without the site name is not counted.

## License

MIT
