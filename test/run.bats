#!/usr/bin/env bats

setup() {
  docker history "$REGISTRY/$REPOSITORY:$TAG" >/dev/null 2>&1
  export IMG="$REGISTRY/$REPOSITORY:$TAG"
}

@test "the image has a disk size under 10MB" {
    run docker images $IMG
    echo 'status:' $status
    echo 'output:' $output
    size="$(echo ${lines[1]} | awk -F '   *' '{ print int($5) }')"
    echo 'size:' $size
    [ "$status" -eq 0 ]
    [ $size -lt 10 ]
}

@test "the image has the apk-install wrapper" {
  run docker run --rm --entrypoint=/bin/sh $IMG -c '[ -x /usr/sbin/apk-install ]'
  echo 'status:' $status
  [ $status -eq 0 ]
}

@test "the image can install package cleanly" {
  run docker run --rm $IMG apk add --update openssl
  echo 'status:' $status
  [ $status -eq 0 ]
}

@test "the apk-install wrapper can install package cleanly" {
  run docker run --rm $IMG apk-install openssl
  echo 'status:' $status
  [ $status -eq 0 ]
}

@test "the timezone is set to UTC" {
  run docker run --rm $IMG date +%Z
  echo 'status:' $status
  echo 'output:' $output
  [ $status -eq 0 ]
  [ "$output" = "UTC" ]
}

@test "the image has the correct repository list" {
  run docker run --rm $IMG cat /etc/apk/repositories
  [ $status -eq 0 ]

  if [ "$TAG" -le "3.2" ]; then
    [[ "${lines[0]}" == "http://dl-cdn.alpinelinux.org/alpine/v$TAG/main" ]]
    [[ "${lines[2]}" == "" ]]
  elif [ "$TAG" = "edge" ]; then
    [[ "${lines[0]}" == "http://dl-cdn.alpinelinux.org/alpine/$TAG/main" ]]
    [[ "${lines[1]}" == "http://dl-cdn.alpinelinux.org/alpine/$TAG/community" ]]
    [[ "${lines[2]}" == "" ]]
  else
    [[ "${lines[0]}" == "http://dl-cdn.alpinelinux.org/alpine/v$TAG/main" ]]
    [[ "${lines[1]}" == "http://dl-cdn.alpinelinux.org/alpine/v$TAG/community" ]]
    [[ "${lines[2]}" == "" ]]
  fi
}

@test "that /var/cache/apk is empty" {
  run docker run --rm $IMG sh -c "ls -1 /var/cache/apk | wc -l"
  echo 'status:' $status
  [ $status -eq 0 ]
}

@test "that the root password is disabled" {
  run docker run --user nobody $IMG su
  echo 'status:' $status
  [ $status -eq 1 ]
}
