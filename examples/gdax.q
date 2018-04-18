/ depends on ws.q, in root directory of repo
\l ws.q
/ depends on reQ - included as submodule, if not cloned recursively, you must correct location
\l reQ/req.q

book:([] sym:`$();time:`timestamp$();bids:();bsizes:();asks:();asizes:())           //schema for book table
trade:([] time:`timestamp$();sym:`$();price:`float$();bid:`float$();ask:`float$();side:`$();tid:`long$();size:`float$())

\d .gdax

depth:5                                                                             //depth to maintain in book table
stdepth:100*depth                                                                    //depth to maintain in state dicts

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

rec.trade:{[t]
  /* record trade record */
  publish[`trade;t];
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

msg.ticker:{
  /* handle ticker (trade) messages */
  x:"SFFFSZjF"$`product_id`price`best_bid`best_ask`side`time`trade_id`last_size#x;  //cast dict fields
  x:@[x;`product_id;.Q.id];                                                         //fix sym
  x:@[x;`time;"p"$];                                                                //cast time to timestamp
  if[not count x`trade_id;x[`trade_id]:0N];                                         //first rec has empty list
  x:`sym`price`bid`ask`side`time`tid`size!value x;                                  //rename fields
  rec.trade `time`sym xcols enlist x;                                               //make table & record
  }

upd:{
  /* entrypoint for received messages */
  j:.j.k x;                                                                         //parse received JSON message
  if[(t:`$j[`type]) in key msg;                                                     //check for handler of this message type
     msg[t]j;                                                                       //pass to relevant message handler
    ];
 }

sub:{[h;s;t]
  t:$[t~`;`trade`depth;(),t];                                                       //expand null to all tables, make list
  /* subscribe to l2 data for a given sym */
  if[`depth in t;
     h .j.j `type`product_ids`channels!(`subscribe;enlist string s;enlist"level2"); //send subscription message
  ];
  if[`trade in t;
     h .j.j `type`product_ids`channels!(`subscribe;enlist string s;enlist"ticker"); //send subscription message
  ];
 }

getref:{[]
  r:.req.get["https://api.gdax.com/products";()!()];                                //get reference data using reQ
  :"SSSFFFSSb*FFbbb"$/:r;                                                           //cast to appropriate data types
 }

\d .

.gdax.ref:.gdax.getref[];                                                           //get reference data
.gdax.h:.ws.open["wss://ws-feed.gdax.com";`.gdax.upd]                               //open websocket to feed
.gdax.sub[.gdax.h;`$"ETH-USD";`];                                                   //subscribe to L2 & trade data for ETH-USD
.gdax.sub[.gdax.h;`$"BTC-GBP";`];                                                   //subscribe to L2 & trade data for BTC-GBP
