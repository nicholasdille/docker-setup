package main

import (
	"context"
	"fmt"
	"encoding/json"
	"time"

	"github.com/regclient/regclient"
	"github.com/regclient/regclient/types/ref"
)

func main() {
	ctx, cancel := context.WithDeadline(context.Background(), time.Now().Add(3 * time.Second))
	defer cancel()

	r, err := ref.New("ghcr.io/nicholasdille/docker-setup/docker:main")
	if err != nil {
		return
	}

	rcOpts := []regclient.Opt{}
	rcOpts = append(rcOpts, regclient.WithUserAgent("docker-setup"))
	rcOpts = append(rcOpts, regclient.WithDockerCreds())
	rc := regclient.New(rcOpts...)
	defer rc.Close(ctx, r)

	m, err := rc.ManifestGet(ctx, r)
	if err != nil {
        fmt.Println(err)
		return
	}

	b, err := json.Marshal(m)
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Println(string(b))
}