\l ws.q

book:([] sym:`$();time:`timestamp$();bids:();bsizes:();asks:();asizes:())           //schema for book table

\d .gdax

depth:5                                                                             //depth to maintain in book table
stdepth:20*depth                                                                    //depth to maintain in state dicts

bidst:(`u#enlist`)!enlist(`float$())!`float$()                                      //bid state dict
askst:(`u#enlist`)!enlist(`float$())!`float$()                                      //ask state dict
lb:(`u#enlist`)!enlist(`bids`bsizes`asks`asizes!())                                 //last book state

/* Redefine publish function to pass to TP for real FH */
publish:upsert                                                                      //define publish function to upsert for example FH

rec.book:{[t;s]
  /* determine if book record needs published & publish if so */
  bk: `bids`bsizes!depth sublist'(key;value)@\:bidst[s];                            //get current bid book up to depth
  bk,:`asks`asizes!depth sublist'(key;value)@\:askst[s];                            //get current ask book up to depth
  if[not bk~lb[s];                                                                  //compare to last book
     publish[`book;@[bk;`sym`time;:;(s;"p"$t)]];                                    //publish record if changed
     lb[s]:bk;                                                                      //record state of last book
   ];
 }

sort.state:{[s]
  /* sort state dictionaries & drop empty levels */
  @[;s;{(where 0=x)_x}]'[`.gdax.bidst`.gdax.askst];                                 //drop all zeros
  @[`.gdax.askst;s;{stdepth sublist asc[key x]#x}];                                 //sort asks ascending
  @[`.gdax.bidst;s;{stdepth sublist desc[key x]#x}];                                //sort bids descending
 }

msg.snapshot:{
  /* handle snapshot messages */
  x:"SSFF"$x;                                                                       //cast dictionary to relevant types
  s:.Q.id x`product_id;                                                             //extract sym, remove bad chars
  askst[s]:stdepth sublist (!/) flip x`asks;                                        //get ask state
  bidst[s]:stdepth sublist (!/) flip x`bids;                                        //get bid state
  rec.book[.z.p;s];                                                                 //record current state of book
 }

msg.l2update:{
  /* handle level2 update messages */
  x:"SSZ*"$x;                                                                       //cast dictionary to relevant types
  s:.Q.id x`product_id;                                                             //extract sym, remove bad chars
  c:"SFF"$/:x`changes;                                                              //extract and cast changes
  {.[`.gdax.askst`.gdax.bidst y[0]=`buy;(x;y 1);:;y 2]}[s]'[c];                     //update state dict(s)
  sort.state[s];                                                                    //sort state dicts
  rec.book[x`time;s];                                                               //record current state of book
 }

upd:{
  /* entrypoint for received messages */
  j:.j.k x;                                                                         //parse received JSON message
  if[(t:`$j[`type]) in key msg;                                                     //check for handler of this message type
     msg[t]j;                                                                       //pass to relevant message handler
    ];
 }

sub:{[h;s]
  /* subscribe to l2 data for a given sym */
  h .j.j `type`product_ids`channels!(`subscribe;enlist string s;enlist"level2");    //send subscription message
 }

\d .

.gdax.h:.ws.open["wss://ws-feed.gdax.com";`.gdax.upd]                               //open websocket to feed
.gdax.sub[.gdax.h;`$"ETH-USD"];                                                     //subscribe to L2 data for ETH-USD
.gdax.sub[.gdax.h;`$"BTC-GBP"];                                                     //subscribe to L2 data for BTC-GBP
