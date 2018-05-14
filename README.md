# ws.q

A simple library for using WebSockets in KDB+/q

Provides function `.ws.open` to open a WebSocket, allowing definition of a per-
socket callback function, tracked in a keyed table `.ws.w`

Additionally, pub/sub functionality is provided by `wsu.q`, with an example
implementation in the form of `wschaintick.q`, a chained tickerplant which
subscribes to a regular kdb+tick TP & republishes received records via 
WebSockets. [See below](#wsuq-wschaintickq) for more details.

## Example (client via `ws.q`)

```
$ q ws.q
KDB+ 3.5 2017.10.11 Copyright (C) 1993-2017 Kx Systems
l32/ 2()core 1945MB jonny grizzly 127.0.1.1 NONEXPIRE

q).bfx.upd:{.bfx.x,:enlist x}                                   //define upd func for bitfinex
q).spx.upd:{.spx.x,:enlist x}                                   //define upd func for spreadex
q).bfx.h:.ws.open["wss://api.bitfinex.com/ws/2";`.bfx.upd]      //open bitfinex socket
q).spx.h:.ws.open["wss://otcsf.spreadex.com/";`.spx.upd]        //open spreadex socket
q).bfx.h .j.j `event`pair`channel!`subscribe`BTCUSD`ticker      //send subscription message over bfx socket
q).bfx.x                                                        //check raw messages stored
"{\"event\":\"info\",\"version\":2,\"platform\":{\"status\":1}}"
"{\"event\":\"subscribed\",\"channel\":\"ticker\",\"chanId\":3,\"symbol\":\"tBTCUSD\",\"pair\":\"BTCUSD\"}"
"[3,[8903.2,67.80649424,8904.2,49.22740929,27.3,0.0031,8904.2,43651.93267067,9177.5,8752]]"
q).spx.x                                                        //check raw messages stored
"{type:\"poll\"}"
"{type:\"poll\"}"
"{type:\"poll\"}"
"{type:\"poll\"}"
q).ws.w                                                         //check list of opened sockets
h| hostname           callback
-| ---------------------------
3| api.bitfinex.com   .bfx.upd
4| otcsf.spreadex.com .spx.upd
```

```
$ q ws.q
KDB+ 3.5 2017.11.30 Copyright (C) 1993-2017 Kx Systems
l64/ 8()core 16048MB jmcmurray homer.aquaq.co.uk 127.0.1.1 EXPIRE 2018.06.30 AquaQ #50170

q).echo.upd:show
q).echo.h:.ws.open["ws://demos.kaazing.com/echo";`.echo.upd]
q).echo.h "hi"
q)"hi"
.echo.h "kdb4life"
q)"kdb4life"
```

### GDAX Feedhandler

As a further example of an application using the library, there is included
a feedhandler for the GDAX cryptocurrency exchange [docs](https://docs.gdax.com/#websocket-feed)

This is located in `examples/gdax.q` and should be started from the root of the repo
with `q examples/gdax.q` to ensure it can locate `ws.q`

In it's provided form, the FH will subscribe to Level 2 data for ETH-USD and BTC-GBP
maintaining a book table within the session. This can be changed to publishing to a 
tickerplant, for example, by modifying the `publish` function

## `wsu.q` & `wschaintick.q`

These scripts (based off `u.q` & `chaintick.q` from kx, respectively) provide pub/sub
functionality for WebSockets, and an example in the form of a chained TP to republish
records over WebSockets.

Given the data is published over WebSockets, this can be consumed in a wide variety of
programming languages (including in q via the client library `ws.q`, although this is
obviously a less efficient option than using kdb+ built in IPC). Some examples are
presented below. In each case, `wschaintick.q` is running on port 5110, along with
a standard kdb+tick tickerplant & a dummy feed.

Subscription is done by opening the WebSocket and then writing a JSON object to the
socket. This object contains three keys, `type`, `tables` and `syms`. `type` is `"sub"`
while `tables` & `syms` are lists of tables & syms to subscribe to. Similar to `u.q`,
an empty list (including leaving out the key) subscribes to everything available.

### q client via `ws.q`

```
jonny@grizzly ~/git/ws.q (master) $ q ws.q
KDB+ 3.5 2017.10.11 Copyright (C) 1993-2017 Kx Systems
l32/ 2()core 1945MB jonny grizzly 127.0.1.1 NONEXPIRE

q)upd:{show x};h:.ws.open["ws://localhost:5110";`upd]
q)h .j.j enlist[`type]!enlist`sub
q)"[\"quote\",[{\"time\":\"0D21:59:47.593326000\",\"sym\":\"INTC\",\"bid\":65.27,\"ask\":66.32,\"bsize\":47,\"asize\":67,\"mode\":\"A\",\"ex\":\"N\"},\n {\"time\":\"0D21:59:47.593326000\",\"sym\":\"INTC\",\"bid\":65.54,\"ask\":67.03,\"b..
"[\"trade\",[{\"time\":\"0D21:59:48.093343000\",\"sym\":\"DOW\",\"price\":24.35,\"size\":24,\"stop\":false,\"cond\":\"A\",\"ex\":\"O\"}]]"
"[\"quote\",[{\"time\":\"0D21:59:48.593450000\",\"sym\":\"GOOG\",\"bid\":108.89,\"ask\":109.99,\"bsize\":54,\"asize\":49,\"mode\":\" \",\"ex\":\"N\"},\n {\"time\":\"0D21:59:48.593450000\",\"sym\":\"DOW\",\"bid\":23.39,\"ask\":25.24,\".. 
"[\"quote\",[{\"time\":\"0D21:59:49.093454000\",\"sym\":\"MSFT\",\"bid\":12.61,\"ask\":13.07,\"bsize\":44,\"asize\":45,\"mode\":\"A\",\"ex\":\"N\"},\n {\"time\":\"0D21:59:49.093454000\",\"sym\":\"DOW\",\"bid\":23.63,\"ask\":24.29,\"bs..
"[\"trade\",[{\"time\":\"0D21:59:49.593353000\",\"sym\":\"INTC\",\"price\":66.12,\"size\":66,\"stop\":false,\"cond\":\"E\",\"ex\":\"N\"},\n {\"time\":\"0D21:59:49.593353000\",\"sym\":\"INTC\",\"price\":66.17,\"size\":72,\"stop\":false..
"[\"quote\",[{\"time\":\"0D21:59:50.093468000\",\"sym\":\"GOOG\",\"bid\":108.33,\"ask\":109.98,\"bsize\":51,\"asize\":44,\"mode\":\"Z\",\"ex\":\"N\"},\n {\"time\":\"0D21:59:50.093468000\",\"sym\":\"HPQ\",\"bid\":31.36,\"ask\":31.62,\"..
\\
```

### Node.js

```
jonny@grizzly ~/git/ws.q (master) $ more eg.js
const WebSocket = require('ws');
const ws = new WebSocket('ws://127.0.0.1:' + process.argv[2]);

ws.on('open', function open() {
  ws.send('{"type":"sub","syms":["AAPL","IBM"]}');
});
ws.on('message', function incoming(data) {
  console.log(data);
});
jonny@grizzly ~/git/ws.q (master) $ node eg.js 5110
["trade",[{"time":"0D22:03:21.093413000","sym":"AAPL","price":132.51,"size":75,"stop":false,"cond":"G","ex":"N"},
 {"time":"0D22:03:21.093413000","sym":"IBM","price":27.03,"size":20,"stop":false,"cond":"A","ex":"N"}]]
["quote",[{"time":"0D22:03:21.593401000","sym":"AAPL","bid":132.01,"ask":133.02,"bsize":32,"asize":77,"mode":"Z","ex":"N"},
 {"time":"0D22:03:21.593401000","sym":"IBM","bid":26.15,"ask":27.98,"bsize":21,"asize":17,"mode":" ","ex":"N"},
 {"time":"0D22:03:21.593401000","sym":"IBM","bid":26.7,"ask":27.89,"bsize":37,"asize":83,"mode":"R","ex":"N"}]]
```
