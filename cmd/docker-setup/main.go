package main

import (
	"github.com/spf13/cobra"
)

var version string = "main"

var (
	rootCmd = &cobra.Command{
		Use:     "docker-setup",
		Version: version,
		Short:   "docker-setup: The container tools installer and updater",
	}
)

func init() {
	rootCmd.PersistentFlags().StringP("file", "f", "tools.yaml", "File with tools definitions")

	initToolCmd()
	initTagCmd()
}

func main() {
	rootCmd.Execute()
}
