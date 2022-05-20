package main

import (
	"fmt"
	"os"

	"github.com/nicholasdille/docker-setup/pkg/tool"
)

var str string = `
tools:
- name: foo
  version: 1.0.0
- name: bar
  version: 1.2.3
`

func main() {
	data := []byte(str)

	tools, err := tool.Load(data)
	if err != nil {
		fmt.Printf("Error loading data: %s\n", err)
		os.Exit(1)
	}

	tools.Print()
}
