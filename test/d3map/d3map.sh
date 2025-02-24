#!/bin/bash

## functions
function padip() {  #Pad IP - fill in missing zeros
  ip=$1
  if [ "$ip" == "" ]; then return; fi
  PADIP=""
  SEGIP="`echo $ip|tr ':' ' '`"
  for S in $SEGIP
  do
    while :
    do
      if [ "`echo $S|cut -b 4`" == "" ]
      then
        S="0$S"
        continue
      fi
      if [ "$PADIP" == "" ]
      then
        PADIP="$S"
      else
        PADIP="$PADIP:$S"
#        echo "PADIP.:$PADIP" 1>&2
      fi
      break
    done
  done
#  echo "PADIP:$PADIP" 1>&2
  if [ "$PADIP" != "" ]
  then
    ip="$PADIP"
  fi
  echo "$ip"
  return
}

(
TS="`date -u +%Y%m%d`"
PEERSFILE="walk.peers.$TS"
#PEERSFILE="walk.peers.`date -u +%Y%m%d`" #Daily
#PEERSFILE="walk.peers.`date -u +%Y%m`" #Monthly
#if [ ! -f d3map.peers ]
#then
  echo "-Fetching http://hia.cjdns.ca/walk/$PEERSFILE as d3map.peers"
  wget -qN http://hia.cjdns.ca/walk/$PEERSFILE -O d3map.peers.new
  if [ "`head -n10 d3map.peers.new|grep -v '^$'|grep ^fc`" == "" ]
  then
    echo "-FAILED"
    rm d3map.peers.new
    exit 1
  fi
  mv d3map.peers.new d3map.peers
#fi

## Make d3map
if [ ! -f d3.v3.min.js ]
then
  echo "-Fetching http://d3js.org/d3.v3.min.js"
  wget -qN http://d3js.org/d3.v3.min.js
fi

echo "-Sorting nodes by order of most peers"
echo -n > d3map.tmp.ips
cat d3map.peers | tr ' ' '\n' | sort | uniq | \
while read IP
do
#  IP="`padip $IP`"
  P=$((`cat d3map.peers | grep $IP | wc -l | cut -d\  -f1`))
  if [ $P -gt 0 ]
  then
#    echo "$P $IP"
    echo "$P $IP" >> d3map.tmp.ips
  fi
done
cat d3map.tmp.ips | sort -rn | cut -d\  -f2 > d3map.tmp.ips.new
mv d3map.tmp.ips.new d3map.tmp.ips
echo "-Found $((`wc -l d3map.tmp.ips|cut -d\  -f1`)) most peered nodes"

echo "-Adding peers to d3map.js"
echo "var links = [" > d3map.js.new
# read top ips to d3map
cat d3map.tmp.ips | \
while read IP
do
  echo "-Parsing $IP ($((`cat d3map.peers | grep -F $IP | tr ' ' '\n' | grep -vF $IP | sort | uniq | wc -l`)) peers, $((`cat d3map.peers | grep -F $IP | sort | uniq | wc -l`)) paths)"
  cat d3map.peers | grep -F "$IP" | sort | uniq | \
  while read IP_SRC IP_DST
  do
#    echo "-Adding $IP_SRC -> $IP_DST"
    if [ "`cat d3map.js.new|grep -F \"$IP_SRC\"|grep -F \"$IP_DST\"`" != "" ]
    then
      continue
    fi
    echo "  {source: \"$IP_SRC\", target: \"$IP_DST\", type: \"peer\"}," >> d3map.js.new
  done
done
echo "  {source: \"fc00::1\", target: \"HIA\", type: \"peer\"}" >> d3map.js.new
echo "];" >> d3map.js.new
mv d3map.js.new d3map.js

PATHS=$((`cat d3map.js|grep '{source: "fc'|wc -l`))
NODES=$((`cat d3map.peers|tr ' ' '\n'|sort|uniq|wc -l`))

echo "-Making d3map.html"
cat <<EOF_MAP > d3map.html.new
<!DOCTYPE html>
<meta charset="utf-8">
<head>
<title>d3map - $NODES nodes | $PATHS paths | $TS</title>
</head>
<!-- http://d3js.org/d3.v3.min.js -->
<script src="d3.v3.min.js"></script>
<style>
.link {
  fill: none;
  stroke: #666;
  stroke-width: 1.5px;
}
.node circle {
  fill: #ccc;
  stroke: #fff;
  stroke-width: 1.5px;
}
text {
  font: 10px sans-serif;
  pointer-events: none;
}
</style>
<body>
<script src="d3map.js"></script>
<script>
var nodes = {};

// Compute the distinct nodes from the links.
links.forEach(function(link) {
  link.source = nodes[link.source] || (nodes[link.source] = {name: link.source});
  link.target = nodes[link.target] || (nodes[link.target] = {name: link.target});
});

var width = window.innerWidth / 100 * 97,
    height = window.innerHeight / 100 * 97;

var force = d3.layout.force()
    .nodes(d3.values(nodes))
    .links(links)
    .size([width, height])
    .linkDistance(10)
    .charge(-100)
    .on("tick", tick)
    .start();
//    .linkDistance(60)
//    .charge(-300)

var svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height);

var link = svg.selectAll(".link")
    .data(force.links())
  .enter().append("line")
    .attr("class", "link");

var node = svg.selectAll(".node")
    .data(force.nodes())
  .enter().append("g")
    .attr("class", "node")
    .on("mouseover", mouseover)
    .on("mouseout", mouseout)
    .call(force.drag);

node.append("circle")
    .attr("r", 8);

node.append("text")
    .attr("x", 12)
    .attr("dy", ".35em")
    .text(function(d) { return d.name; });

function tick() {
  link
      .attr("x1", function(d) { return d.source.x; })
      .attr("y1", function(d) { return d.source.y; })
      .attr("x2", function(d) { return d.target.x; })
      .attr("y2", function(d) { return d.target.y; });

  node
      .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
}

function mouseover() {
  d3.select(this).select("circle").transition()
      .duration(750)
      .attr("r", 16);
}

function mouseout() {
  d3.select(this).select("circle").transition()
      .duration(750)
      .attr("r", 8);
}
</script>
EOF_MAP

echo "-Done making d3map.html"
mv d3map.html.new d3map.html
echo "-Saved $NODES nodes with $PATHS paths from $TS."
echo

) 2>&1 | tee d3map.log

exit

#EOF#
