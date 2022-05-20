package main

import (
	"fmt"

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(toolCmd)
	toolCmd.AddCommand(listCmd)
	toolCmd.AddCommand(searchCmd)
}

var toolCmd = &cobra.Command{
	Use:     "tool",
	Aliases: []string{"t"},
	Short:   "XXX",
	Long:    `XXX`,
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List tools",
	Long:  `XXX`,
	Run: func(cmd *cobra.Command, args []string) {
		// *** add code to invoke automation end points below ***
		fmt.Println("Executing 'tool list' placeholder command")
	},
}

var searchCmd = &cobra.Command{
	Use:   "search",
	Short: "Search for tool",
	Long:  `XXX`,
	Run: func(cmd *cobra.Command, args []string) {
		// *** add code to invoke automation end points below ***
		fmt.Println("Executing 'tool search' placeholder command")
	},
}
