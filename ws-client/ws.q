\d .ws

/ if reQ not loaded, define necessary components here
if[not `req in key `;
  .url.parse0:{[q;x]
    if[x~hsym`$255#"a";'"hsym too long - consider using a string"];                   //error if URL~`: .. too long
    x:.url.sturl x;                                                                   //ensure string URL
    p:x til pn:3+first ss[x;"://"];                                                   //protocol
    uf:("@"in x)&first[ss[x;"@"]]<first ss[pn _ x;"/"];                               //user flag - true if username present
    un:pn;                                                                            //default to no user:pass
    u:-1_$[uf;(pn _ x) til (un:1+first ss[x;"@"])-pn;""];                             //user:pass
    d:x til dn:count[x]^first ss[x:un _ x;"/"];                                       //domain
    a:$[dn=count x;enlist"/";dn _ x];                                                 //absolute path
    o:`protocol`auth`host`path!(p;u;d;a);                                             //create URL object
    :$[q;@[o;`path`query;:;query o`path];o];                                          //split path into path & query if flag set, return
  };
  .url.sturl:{(":"=first x)_x:$[-11=type x;string;]x};
  .url.hsurl:{`$":",.url.sturl x};
  .req.query:`method`url`hsym`path`headers`body`bodytype!();
  .req.proxy:{[u]
    p:(^/)`$getenv`$(floor\)("HTTP";"NO"),\:"_PROXY";                                 //check HTTP_PROXY & NO_PROXY env vars, upper & lower case - fill so p[0] is http_, p[1] is no_
    t:max(first ":"vs u[`url]`host)like/:{(("."=first x)#"*"),x}each"," vs string p 1; //check if host is in NO_PROXY env var
    t:not null[first p]|t;                                                            //check if HTTP_PROXY is defined & host isn't in NO_PROXY
    :$[t;@[;`proxy;:;p 0];]u;                                                         //add proxy to URL object if required
  };
  .req.enchd:{[d]
    k:2_@[k;where 10<>type each k:(" ";`),key d;string];                              //convert non-string keys to strings
    v:2_@[v;where 10<>type each v:(" ";`),value d;string];                            //convert non-string values to strings
    :("\r\n" sv ": " sv/:flip (k;v)),"\r\n\r\n";                                      //encode headers dict to HTTP headers
  };
  .req.buildquery:{[q]
    r:string[q`method]," ",q[`url;`path]," HTTP/1.1\r\n",                             //method & endpoint TODO: fix q[`path] for proxy use case
    "Host: ",q[`url;`host],$[count q`headers;"\r\n";""],                              //add host string
         .req.enchd[q`headers],                                                       //add headers
         $[count q`body;q`body;""];                                                   //add payload if present
    :r;                                                                               //return complete query string
  };
 ];

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
  .z.wc h;                                                              //remove h from .ws.servers
 }

.ws.closea:{.ws.close each (0!.ws.w)[`h]}                               //close all opened websockets

\d .
