docker_run \
    --workdir /go/src/github.com/nelhage/reptyr \
    <<EOF
git clone -q --config advice.detachedHead=false --depth 1 --branch "reptyr-${version}" https://github.com/nelhage/reptyr .
export LDFLAGS=-static
make reptyr
mkdir -p /target/bin /target/share/man/man1
cp reptyr /target/bin/
cp reptyr.1 /target/share/man/man1/
EOF

