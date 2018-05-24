\d .ws
\l reQ/req.q

VERBOSE:@[value;`.ws.VERBOSE;$[count .z.x;"-verbose" in .z.x;0b]];      //default to non-verbose output

w:([h:`int$()] hostname:`$();callback:`$())                             //table for recording open websockets

.z.ws:{value[w[.z.w]`callback]x}                                        //pass messages to relevant handler

open0:{[x;y;v]
  pr:.req.proxy h:.req.host x;                                          //handle proxy if needed,get host
  hs:.req.hsurl[.req.prot[x],h];                                        //get hsym of host
  d:(enlist"Origin")!enlist h;                                          //use Origin header
  s:first r:hs d:.req.buildquery[`GET;pr;x;h;d;()];                     //build query & send
  if[v;-1"-- REQUEST --\n",string[hs]," ",d];                           //if verbose, log request
  if[v;-1"-- RESPONSE --\n",last r];                                    //if verbose, log response
  w,:(s;`$h;y);                                                         //record handle & callback in table
  :r;                                                                   //return response
 }

open:{neg first open0[x;y;.ws.VERBOSE]}                                 //return neg handle for messaging

\d .
