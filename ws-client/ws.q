\d .ws

VERBOSE:@[value;`.ws.VERBOSE;$[count .z.x;"-verbose" in .z.x;0b]];      //default to non-verbose output

w:([h:`int$()] hostname:`$();callback:`$())                             //table for recording open websockets

.ws.onmessage.server:{value[w[.z.w]`callback]x}                         //pass messages to relevant handler

open0:{[x;y;v]
  q:@[.req.query;`method`url;:;(`GET;.url.parse0[0]x)];                 //create reQ query object
  q:.req.proxy q;                                                       //handle proxy if needed
  hs:.url.hsurl`$raze q ./:enlist[`url`protocol],$[`proxy in key q;1#`proxy;enlist`url`host]; //get hostname as handle
  q[`headers]:(enlist"Origin")!enlist q[`url;`host];                    //use Origin header
  s:first r:hs d:.req.buildquery[q];                                    //build query & send
  if[v;-1"-- REQUEST --\n",string[hs]," ",d];                           //if verbose, log request
  if[v;-1"-- RESPONSE --\n",last r];                                    //if verbose, log response
  servers,:(s;hs);                                                      //record handle & callback in table
  w,:(s;hs;y);                                                          //record handle & callback in table
  :r;                                                                   //return response
 }

open:{neg first open0[x;y;.ws.VERBOSE]}                                 //return neg handle for messaging

.ws.close:{[h]
  h:abs h;
  if[all(h in key .ws.w;h in key .z.W);hclose h];                       //close handle if h is found both in .ws.w and .z.W (all opened handles)
  .ws.w:.ws.w _ h;                                                      //remove h from .ws.w
  .ws.servers: .ws.servers _ h;                                         //remove h from .ws.servers
 }

.ws.closea:{ each[.ws.close;(0!.ws.w)[`h]] }                            //close all opened websockets

\d .
