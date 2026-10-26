# Building InfiniLink Plugins

Plugins are small JavaScript files that teach InfiniLink new tricks. They can talk to your watch over Bluetooth, call web APIs, read and write files on the watch, control Apple Music, and use your location.

> [!NOTE]
> Plugins are still in beta. To try them, turn on Developer Mode, then **Developer → Enable Plugins (beta)**. You'll find a new **Plugins** section on your watch's page.

- [Quick start](#quick-start)
- [The header](#the-header)
- [How plugins run](#how-plugins-run)
- [Globals](#globals)
- [Modules](#modules): [watches](#watches), [fs](#fs), [http](#http), [storage](#storage), [media](#media), [volume](#volume), [location](#location)
- [Limits](#limits)
- [Debugging](#debugging)
- [PinePartner compatibility](#pinepartner-compatibility)
- [Examples](#examples)

## Quick start

Here's a plugin that says hello whenever your watch connects. Save it as `hello.js`:

```js
// ==InfiniLink Plugin==
// @id hello
// @name Hello
// @description Says hello when your watch connects
// @param string greeting Hello!
// ==/InfiniLink Plugin==

const watches = require("watches");

function onConnected(watch) {
    watch.sendNotification(params.greeting, "From your first plugin");
}

watches.addEventListener("connected", onConnected);
watches.all.forEach(onConnected);
```

To install it, open **Plugins**, tap **+**, and pick **Paste Code**, **Choose File...**, or **From URL...**. You'll see the plugin's name and the permissions it wants before anything is installed. Once it's in, open it and flip it on.

Want to ship an update? Just import it again with the same `@id`. Its settings and on/off state carry over.

## The header

Every plugin starts with a block of `//` comments. InfiniLink reads this without running any of your code, which is how it can tell people what a plugin needs before they install it.

```js
// ==InfiniLink Plugin==
// @id home-dashboard
// @name Home Dashboard
// @description Control your lights from your watch
// @author Your Name
// @permission HTTP
// @param string endpoint http://homeassistant.local:8123
// @param secret token
// ==/InfiniLink Plugin==
```

The very first line has to be `// ==InfiniLink Plugin==`, and the block ends at `// ==/InfiniLink Plugin==`. Blank `//` lines are fine, but unknown keys aren't.

| Key | Required | Notes |
| --- | --- | --- |
| `@id` | Yes | Letters, numbers, `-`, `_`, and `.`. It has to be unique, because it's how InfiniLink knows which plugin an import replaces. |
| `@name` | Yes | Shown in the plugin list. |
| `@description` | No | Shown under the name. |
| `@author` | No | |
| `@permission` | No | One per line. See [permissions](#permissions). |
| `@param` | No | One per line. See [parameters](#parameters). |

### Permissions

Some modules need a permission first. If you `require()` one without asking for it, you'll get an error.

| Permission | Unlocks | What people see |
| --- | --- | --- |
| `HTTP` | [`http`](#http) | Send HTTP requests |
| `FILESYSTEM` | [`fs`](#fs) | Read and write files on your watch |
| `MEDIA_CONTROL` | [`media`](#media) | Control and see what's playing in Apple Music |
| `VOLUME_CONTROL` | [`volume`](#volume) | Change your phone's volume |
| `LOCATION` | [`location`](#location) | Access your location |

[`watches`](#watches) and [`storage`](#storage) work without asking.

### Parameters

Parameters are settings people fill in on your plugin's page, like an API URL or a token. You read them from [`params`](#params).

```
// @param <type> <name> [default]
```

| Type | Shows up as | Type in `params` |
| --- | --- | --- |
| `string` | Text field | String |
| `secret` | Password field, kept in the Keychain | String |
| `int` | Number field | Number |
| `boolean` | Switch | Boolean |

Names can use letters, numbers, and `_`, and defaults can't have spaces. When someone changes a setting, your plugin restarts with the new value once they leave its page.

## How plugins run

- Every plugin gets its own JavaScript engine and thread, so a slow or stuck plugin won't freeze InfiniLink or anyone else's plugin.
- Your file runs once, top to bottom, when the plugin starts. From then on, your code only runs from the events and timers you set up.
- Plugins start when InfiniLink launches, when they're turned on, and again whenever their code or settings change.
- Calls like `http.request()` and `fs.read()` wait for their result before returning. That only pauses your plugin, nothing else.
- When an InfiniLink API fails, it throws a normal JavaScript exception, so `try`/`catch` works the way you'd expect.
- Modern JavaScript is fine: `const`, arrow functions, `?.`, `??`, classes, and so on. There's no DOM, `fetch`, npm, or way to load other files, though.
- Plugins keep running in the background for as long as iOS lets InfiniLink run. That's usually the whole time it's connected to your watch, but iOS doesn't promise it, so don't count on exact timing.

## Globals

You can use these anywhere, no `require()` needed.

### console

`console.log()`, `console.info()`, `console.warn()`, and `console.error()` all show up in **Developer → Debug Logs → Plugins**. Objects are printed as JSON. Warnings appear as errors there, since the log only has those two levels.

### timer

```js
const id = timer.setInterval(() => console.log("tick"), 1000); // 100 ms at the fastest
timer.setTimeout(() => console.log("once"), 500);
timer.clear(id);
```

If you're used to the browser, `setTimeout`, `setInterval`, `clearTimeout`, and `clearInterval` are there too. Extra arguments aren't passed along to your callback.

### params

Your plugin's [parameters](#parameters), already converted to the right types.

```js
const url = params.endpoint + "/api/";
```

### require

`require(name)` gives you one of the [modules](#modules) below.

## Modules

### watches

```js
const watches = require("watches");
```

| | |
| --- | --- |
| `watches.all` | The connected watch in an array, or an empty array if nothing's connected. |
| `watches.addEventListener("connected", watch => {})` | Called when a watch connects and is ready to use. |
| `watches.addEventListener("disconnected", () => {})` | Called when the watch disconnects. |
| `watches.removeEventListener(event, callback)` | |

The watch might already be connected by the time your plugin starts, so set things up in both places:

```js
watches.addEventListener("connected", setUp);
watches.all.forEach(setUp);
```

#### Watch

| | |
| --- | --- |
| `watch.isConnected` | |
| `watch.sendNotification(title, body)` | Pops up a notification on the watch, as long as watch notifications are turned on. |
| `watch.getService(uuid)` | Takes a full UUID string, or a number for 16-bit UUIDs like `0x180D`. |

#### Services and characteristics

```js
const service = watch.getService("00060000-78fc-48fe-8e23-433b3a1942d0");
const layout = service.getCharacteristic("00060002-78fc-48fe-8e23-433b3a1942d0");
```

| | |
| --- | --- |
| `characteristic.uuid` | |
| `characteristic.write(value)` | Takes a string (sent as UTF-8), an `ArrayBuffer`, a typed array like `Uint8Array`, or a plain array of bytes. |
| `characteristic.read()` | Returns an `ArrayBuffer`. Gives up and throws after 5 seconds. |
| `characteristic.readString()` | Same as `read()`, but decoded as UTF-8. |
| `characteristic.addEventListener("notify", buffer => {})` | Turns on notifications and hands you each new value as an `ArrayBuffer`. |
| `characteristic.removeEventListener("notify", callback)` | |

`write()`, `read()`, and `addEventListener()` throw if the characteristic isn't there. Usually that means the watch isn't connected, or its firmware doesn't have that service.

Notify listeners go away when the watch disconnects, so add them back in your `connected` handler.

To keep firmware updates safe, plugins can't touch the update service (`00001530-…`) or the file transfer characteristic (`adaf0200-…`). For files, use [`fs`](#fs).

### fs

Needs `@permission FILESYSTEM`. Lets you work with files on the watch.

```js
const fs = require("fs");
```

| | |
| --- | --- |
| `fs.read(path)` | Returns an `ArrayBuffer`, or `undefined` if there's no such file. |
| `fs.readString(path)` | Same as `read()`, but decoded as UTF-8. |
| `fs.list(path)` | Returns `[{ name, isDirectory, size, modified }]`. |
| `fs.write(path, data)` | Takes the same values as `characteristic.write()`. Returns `true` if it worked. |
| `fs.mkdir(path)` | Returns `true` if it worked. |
| `fs.delete(path)` | Returns `true` if it worked. |

You can read anything, and change anything except:

- `/settings.dat`, where the watch keeps its settings.
- `/fonts` and `/images`, where InfiniTime keeps external resources.

InfiniLink looks after those itself, so writing, deleting, or making folders there throws. Paths can't contain `..` either.

### http

Needs `@permission HTTP`.

```js
const http = require("http");

// Waits for the response and gives you the body as a string
const body = http.request("GET", "https://example.com/data.json");
const data = JSON.parse(body);

// With options
http.request("POST", url, {
    headers: { Authorization: "Bearer " + params.token },
    body: JSON.stringify({ entity_id: "light.kitchen" }),
    timeout: 10000 // Milliseconds, 5000 by default
});

// With a callback, so your plugin doesn't wait around
http.request("GET", url, body => console.log(body));
```

- If a request fails, the waiting version throws. The callback version logs the error and never calls your callback.
- Error responses like a 404 still give you the body. You can't read the status code yet.
- `http://` only works for local addresses like `homeassistant.local`. Everything else needs `https://`.
- The first time a plugin talks to something on your network, iOS will ask for local network access.

### storage

Remembers things between restarts. You can save anything JSON can hold.

```js
const storage = require("storage");

storage.set("lastTask", { name: "Email", at: "10:30" });
const last = storage.get("lastTask"); // undefined if it isn't set
storage.remove("lastTask");
storage.keys();
storage.clear();
```

Setting something to `undefined` removes it. Each plugin gets 512 KB. Storage is deleted along with the plugin, and people can wipe it with **Clear Stored Data** in the plugin's **⋯** menu.

### media

Needs `@permission MEDIA_CONTROL`. iOS only lets apps see and control Apple Music, so this won't work with Spotify or other players.

```js
const media = require("media");

media.play();
media.pause();
media.next();
media.previous();
media.seek(30);    // Seconds
media.volume = 8;  // 0-15, same as volume.musicStream.volume

const state = media.state; // undefined when nothing's playing
// { isPlaying, position, duration, title, artist, album }

media.addEventListener("change", state => {
    // Called when the song changes, or playback starts or stops. state is null when nothing's playing
});
```

`change` doesn't fire as a song plays along, so read `media.state` whenever you need the current position. Heads up: changing songs can fire it twice.

### volume

Needs `@permission VOLUME_CONTROL`. iPhones only have one output volume, so the music stream is the only one here.

```js
const volume = require("volume");

volume.musicStream.volume;          // 0-15
volume.musicStream.volume = 10;
volume.musicStream.adjustVolume(1); // Or -1
```

### location

Needs `@permission LOCATION`, and InfiniLink needs to be allowed to use your location.

```js
const location = require("location");

const here = location.getCurrent(); // Throws if your location isn't available
// { latitude, longitude, altitude, accuracy }

const last = location.getLast(); // undefined if there's no recent location

location.addEventListener("change", loc => {
    // Called as the phone moves, roughly every 100 meters
});
```

- `getCurrent()` waits up to 15 seconds.
- As long as any plugin has a `change` listener, the phone keeps tracking location, even in the background. That costs battery, so remove the listener once you're done with it.

## Limits

| | |
| --- | --- |
| Fastest timer | 100 ms |
| HTTP timeout | 5 seconds by default |
| Characteristic `read()` timeout | 5 seconds |
| `location.getCurrent()` timeout | 15 seconds |
| Storage | 512 KB per plugin |

## Debugging

- **Developer → Debug Logs → Plugins** has everything your plugins print, plus any errors and the line they came from.
- To check which version is installed, open the plugin's **⋯** menu, then **Info → Code**.
- No watch handy? On the iOS simulator, tap **Pair Simulated Watch** when connecting. Plugins treat it like a real watch, and a fake Apple Music player stands in for `media` and `volume`. You'll find controls for both in **Developer**, along with the last notification the watch got.
- If a plugin gets stuck in an endless loop, it'll keep running until InfiniLink restarts. Turn it off first so it doesn't start up again.

## PinePartner compatibility

InfiniLink also understands the `// ==PinePartner Plugin==` header, so most [PinePartner](https://github.com/pipe01/PinePartner) plugins work as-is. Here's what's different:

- **Missing:** the `notifications` module and the `RECEIVE_NOTIFICATIONS` permission, because iOS doesn't let apps read other apps' notifications. InfiniLink already sends your notifications to the watch on its own. `watch.address`, `watch.setTime()`, and `watch.setCurrentWeather()` aren't here either.
- **`volume`:** only `musicStream`.
- **`media`:** Apple Music only.
- **`location`:** the accuracy argument to `getCurrent()` is ignored.
- **Only in InfiniLink:** `fs`, `storage`, `media.seek()`, `media.volume`, the `change` events on `media` and `location`, and the browser-style timer globals.

## Examples

### Show each new song on your watch

```js
// ==InfiniLink Plugin==
// @id now-playing
// @name Now Playing
// @description Shows each new song on your watch
// @permission MEDIA_CONTROL
// ==/InfiniLink Plugin==

const media = require("media");
const watches = require("watches");

let lastTitle;

media.addEventListener("change", state => {
    if (!state || !state.isPlaying || state.title === lastTitle) return;
    lastTitle = state.title;

    watches.all.forEach(watch => watch.sendNotification(state.title, state.artist ?? ""));
});
```

### Get a reminder when you arrive somewhere

```js
// ==InfiniLink Plugin==
// @id arrival-reminder
// @name Arrival Reminder
// @permission LOCATION
// @param string latitude
// @param string longitude
// @param string message
// ==/InfiniLink Plugin==

const location = require("location");
const watches = require("watches");
const storage = require("storage");

// Rough distance in meters, good enough over short distances
function distance(a, b) {
    const x = (b.longitude - a.longitude) * Math.cos((a.latitude * Math.PI) / 180);
    const y = b.latitude - a.latitude;
    return Math.sqrt(x * x + y * y) * 111320;
}

const target = { latitude: Number(params.latitude), longitude: Number(params.longitude) };

location.addEventListener("change", loc => {
    const isHere = distance(loc, target) < 150;

    // Only remind once per visit, even if the plugin restarts
    if (isHere && !storage.get("isHere")) {
        watches.all.forEach(watch => watch.sendNotification("You're here", params.message));
    }
    storage.set("isHere", isHere);
});
```

### Log your heart rate

```js
// ==InfiniLink Plugin==
// @id heart-log
// @name Heart Rate Log
// ==/InfiniLink Plugin==

const watches = require("watches");

function setUp(watch) {
    const heartRate = watch.getService(0x180D).getCharacteristic("2A37");

    heartRate.addEventListener("notify", buffer => {
        const bytes = new Uint8Array(buffer);
        console.log("Heart rate:", bytes[1]);
    });
}

watches.addEventListener("connected", setUp);
watches.all.forEach(setUp);
```
