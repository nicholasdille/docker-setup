package main

import (
	"github.com/spf13/cobra"
)

var (
	rootCmd = &cobra.Command{
		Use:   "docker-setup",
		Short: "docker-setup: The container tools installer and updater",
		Long:  `docker-setup: XXX`,
	}
)

func init() {
	rootCmd.PersistentFlags().StringP("file", "f", "tools.yaml", "XXX")
}

func main() {
	rootCmd.Execute()
}
