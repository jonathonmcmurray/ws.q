# ws.q

A simple library for using WebSockets in KDB+/q

Provides function `.ws.open` to open a WebSocket, allowing definition of a per-
socket callback function, tracked in a keyed table `.ws.w`

## Example

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

## GDAX Feedhandler

As a further example of an application using the library, there is included
a feedhandler for the GDAX cryptocurrency exchange [docs](https://docs.gdax.com/#websocket-feed)

This is located in `examples/gdax.q` and should be started from the root of the repo
with `q examples/gdax.q` to ensure it can locate `ws.q`

In it's provided form, the FH will subscribe to Level 2 data for ETH-USD and BTC-GBP
maintaining a book table within the session. This can be changed to publishing to a 
tickerplant, for example, by modifying the `publish` function
>>>>>>> Stashed changes
