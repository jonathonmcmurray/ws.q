\d .ws
\l reQ/req.q

VERBOSE:0b;                                                             //default to non-verbose output

w:([h:`int$()] hostname:`$();callback:`$())                             //table for recording open websockets

.z.ws:{value[w[.z.w]`callback]x}                                        //pass messages to relevant handler

hd:()!()                                                                //default headers for request
hd[`Upgrade]:"websocket";
hd[`Connection]:"Upgrade";
hd[`$"Sec-WebSocket-Version"]:"13";
/hd[`$"Sec-WebSocket-Key"]:.req.auth 16?.Q.an;                          //FIX - this appears to break GDAX, might be incorrect
hd[`$"Sec-WebSocket-Extensions"]:"permessage-deflate; client_max_window_bits";

open0:{[x;y;v]
  pr:.req.proxy h:.req.host x;                                          //handle proxy if needed,get host
  hs:.req.hsurl[.req.prot[x],h];                                        //get hsym of host
  d:hd;                                                                 //get default headers
  d[`Origin]:h;                                                         //insert origin
  d:$[11=type k:key d;string k;k]!value d;                              //convert to strings TODO - make function, maybe in reQ
  s:first r:hs d:.req.buildquery[`GET;pr;x;h;d;()];                     //build query & send
  if[v;-1"-- REQUEST --\n",string[hs]," ",d];                           //if verbose, log request
  if[v;-1"-- RESPONSE --\n",last r];                                    //if verbose, log response
  w,:(s;`$h;y);                                                         //record handle & callback in table
  :r;                                                                   //return response
 }

open:{neg first open0[x;y;.ws.VERBOSE]}                                 //return neg handle for messaging

\d .
