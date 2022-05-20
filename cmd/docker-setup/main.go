package main

import (
	"fmt"
	"io/ioutil"
	"os"

	"github.com/spf13/cobra"

	"github.com/nicholasdille/docker-setup/pkg/tool"
)

var (
	rootCmd = &cobra.Command{
		Use:   "docker-setup",
		Short: "docker-setup: The container tools installer and updater",
		Long:  `docker-setup: XXX`,
	}
)

var tools []tool.Tool

func init() {
	rootCmd.PersistentFlags().StringP("file", "f", "tools.yaml", "XXX")
}

func main() {
	rootCmd.Execute()

	filename, err := rootCmd.PersistentFlags().GetString("file")
	if err != nil {
		fmt.Printf("Error retrieving file flag: %s\n", err)
		os.Exit(1)
	}

	data, err := ioutil.ReadFile(filename)
	if err != nil {
		fmt.Printf("Error loading file contents: %s\n", err)
		os.Exit(1)
	}
	
	tools, err := tool.Load(data)
	if err != nil {
		fmt.Printf("Error loading data: %s\n", err)
		os.Exit(1)
	}

	tools.Print()
}
