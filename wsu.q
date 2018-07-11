/wsu.q
/websocket pubsub functionality
/based off kx u.q

\d .wsu
init:{w::t!(count t::tables`.)#()}

del:{w[x]_:w[x;;0]?y};.z.wc:{del[;x]each t};

sel:{$[`~y;x;select from x where sym in y]}

pub:{[t;x]{[t;x;w]if[count x:sel[x]w 1;(neg first w).j.j(t;x)]}[t;x]each w t}

add:{[h;x;y]$[(count w x)>i:w[x;;0]?h;.[`.wsu.w;(x;i;1);union;y];w[x],:enlist(h;y)];(x;$[99=type v:value x;sel[v]y;0#v])}

sub:{[h;x;y]if[x~`;:sub[h;;y]each t];if[not x in t;'x];del[x]h;add[h;x;y]}

end:{(neg union/[w[;;0]])@\:(`.u.end;x)}

.z.ws:{
  if[`sub=(x:"S"$.j.k x)[`type];
     k:`table`tables `tables in key x;                                              //get key for table(s)
     if[-11=type x k;:sub[.z.w]. x(k;`syms)];                                       //if single table, subscribe
     if[11=type x k;:sub[.z.w;;x`syms] each x k];                                   //if multiple tables, subscribe each
    ];
 }
