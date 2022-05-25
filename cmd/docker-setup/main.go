package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/nicholasdille/docker-setup/pkg/tool"
)

var version string = "main"

var header string = `
     _             _
    | |           | |                                  _
  __| | ___   ____| |  _ _____  ____ _____ ___ _____ _| |_ _   _ ____
 / _  |/ _ \ / ___) |_/ ) ___ |/ ___|_____)___) ___ (_   _) | | |  _ \
( (_| | |_| ( (___|  _ (| ____| |        |___ | ____| | |_| |_| | |_| |
 \____|\___/ \____)_| \_)_____)_|        (___/|_____)  \__)____/|  __/
                                                                |_|
`

var (
	rootCmd = &cobra.Command{
		Use:     "docker-setup",
		Version: version,
		Short:   header + "The container tools installer and updater",
	}
)

func init() {
	rootCmd.PersistentFlags().StringP("file", "f", "tools.yaml", "File with tools definitions")

	initDescribeCmd()
	initGenerateCmd()
	initInstallCmd()
	initListCmd()
	initSearchCmd()
	initTagsCmd()
}

func main() {
	rootCmd.Execute()
}

var tools tool.Tools

func load() {
	filename, err := rootCmd.PersistentFlags().GetString("file")
	if err != nil {
		fmt.Printf("Error retrieving file flag: %s\n", err)
		os.Exit(1)
	}

	tools, err = tool.LoadFromFile(filename)
	if err != nil {
		fmt.Printf("Error loading from file %s: %s\n", filename, err)
		os.Exit(1)
	}
}
