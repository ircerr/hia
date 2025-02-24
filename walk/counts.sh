ls walk.peers*|sort|while read X; do echo -n "$X ";cat $X|tr ' ' '\n'|sort|uniq|wc -l;done > counts.txt

