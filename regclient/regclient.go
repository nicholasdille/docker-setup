package main

import (
	"context"
	"fmt"
	"encoding/json"
	"os"
	"time"

	"github.com/regclient/regclient"
	"github.com/regclient/regclient/types/ref"
	"github.com/regclient/regclient/types/manifest"
)

func main() {
	fmt.Printf("Processing %s\n", os.Args[1])

	ctx, cancel := context.WithDeadline(context.Background(), time.Now().Add(10 * time.Second))
	defer cancel()

	r, err := ref.New(os.Args[1])
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

	if m.IsList() {
		fmt.Println("list")

		if mi, ok := m.(manifest.Indexer); ok {
			manifests, err := mi.GetManifestList()
			if err != nil {
				fmt.Println("Error getting manifests")
				os.Exit(1)
			}
			fmt.Printf("Manifest count: %d\n", len(manifests))

			for i, manifest := range manifests {
				fmt.Printf("Manifest %d Platform %s\n", i, manifest.Platform.Architecture)
				if manifest.Platform.Architecture == os.Args[2] {
					// TODO fetch digest
					break
				}
			}
		}

	} else {
		fmt.Println("no list")

		if mi, ok := m.(manifest.Imager); ok {
			fmt.Printf("Type of mi: %T", mi)
			layers, err := mi.GetLayers()
			if err != nil {
				fmt.Println("Error getting layers")
				os.Exit(1)
			}
			fmt.Printf("Layer count: %d\n", len(layers))
		}
	}
}