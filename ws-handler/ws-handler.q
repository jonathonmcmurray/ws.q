/ WebSockets handler module; create & receive WebSocket connections in a managable way
\d .ws

/ Set up client/server tables & handlers without overwriting, so this script
/ can be loaded multiple times without issue
clients:@[value;`.ws.clients;([h:`int$()] hostname:`$())];              //clients = incoming connections over ws
servers:@[value;`.ws.servers;([h:`int$()] hostname:`$())];              //servers = outgoing connections over ws

onmessage.client:@[value;`.ws.onmessage.client;{{x}}];                  //default echo
onmessage.server:@[value;`.ws.onmessage.server;{{x}}];                  //default echo

.z.ws:{.ws.onmessage[$[.z.w in key servers;`server;`client]]x}          //pass messages to relevant handler func
.z.wo:{clients,:(.z.w;.z.h)}                                            //log incoming connections
.z.wc:{{delete from y where h=x}[.z.w] each `.ws.clients`.ws.servers}   //clean up closed connections

\d .
