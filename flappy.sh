#!/bin/bash

# cleaning up former runs
rm *-results

# this value controls parralellism
P=10
NODES=`cat /dev/stdin`

  echo "commencing tcp scan of nodes"
for a in `seq 1 10` # This count must match the $total variable in order to determine node health properly
do
  for i in $NODES
  do
    # This is what took me the most time, finding a way not to run out of forks, while keeping it performant.
    ((f=f%P)); ((f++==0)) && wait
    # nc doesn't output normally, hence why we're sending everything to stdout. nor does it have timeouts built in so i put them in here to get performance.
    nc -z -G 1 $i $1 >> $i-results 2>&1 &
  done
done

# Here we make sure nc is done before we begin our evaluation
while [ `ps | grep "nc -z*"| wc -l` -gt 1 ]
  do
  sleep 1
done

# here we evaluate whether something is available 100% success, flapping <100% success, or down 0% success.
for b in `ls *-results`
do
  total=10 #This variable must match the ending number in the seq command above to determine node health proplerly.
  succeed=`grep "succeeded!" $b | wc -l`
  
  if [ $succeed -eq 0 ]
  then
    echo "$b is down"
  elif [ $total -gt $succeed ]
  then
    echo "$b is flappy"
  fi

  if [ $total -eq $succeed ]
  then
    echo "$b is available"
  fi
done
exit 0
