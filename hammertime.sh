#! /bin/sh

function users() {
  local userlist="joe bob alice harry brandon sarah jgomez zorah kbarber batman charlie fed boosman lisa yantis chiang jimbob james heather"
  echo $userlist | tr ' ' "\n" | shuf
}

function containers() {
  echo $(docker ps -q) | shuf
}

for USER in `users`; do
  (
    echo "Creating ${USER}"
    curl --silent --show-error --fail -X POST -F "username=${USER}" -F 'password=something' -F 'session=12345' http://localhost/new
    echo
  ) &

  # sleep for a random fraction of a second before invoking the next subshell
  sleep $(bc -l <<< "scale=2 ; ${RANDOM}/32767")
done
wait

for NODE in `containers`; do
  (
    echo "Requesting certs for ${NODE}"
    docker exec -d ${NODE} /opt/puppetlabs/bin/puppet agent -t
  ) &

  # sleep between 0 and 10 seconds
  sleep $(( $RANDOM % 10 ))
done
wait

# just to make sure we've got the CSRs flushed to disk
sleep 5
sync

puppet cert sign --all
puppet code deploy --all --wait

# just to make sure we've got the certs flushed to disk
sleep 5
sync

for NODE in `containers`; do
  (
    echo "Initial configuration for ${NODE}"
    docker exec -d ${NODE} /opt/puppetlabs/bin/puppet agent -t
  ) &

  # sleep between 0 and 10 seconds
  sleep $(( $RANDOM % 10 ))
done
# let's let the first iteration complete before we start pounding the server
wait

puppet code deploy --all --wait

# Simulate the classroom with 10 iterations of random Puppet runs, some in parallel
for i in {1..10};do
  for NODE in `containers`; do
    (
      echo "Running Puppet on ${NODE} (${i})"
      docker exec -d ${NODE} /opt/puppetlabs/bin/puppet agent -t
    ) &

    # sleep between 0 and 60 seconds
    sleep $(( $RANDOM % 60 ))
  done

  # sleep between 0 and 5 minutes
  sleep $(( $RANDOM % 300 ))
  puppet agent -t
  puppet code deploy --all --wait
done
