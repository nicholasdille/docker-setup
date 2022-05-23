package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/nicholasdille/docker-setup/pkg/tool"
)

func init() {
	rootCmd.AddCommand(toolCmd)
	toolCmd.AddCommand(getCmd)
	toolCmd.AddCommand(describeCmd)
	toolCmd.AddCommand(searchCmd)
}

var tools tool.Tools

var toolCmd = &cobra.Command{
	Use:     "tool",
	Aliases: []string{"t"},
	Short:   "XXX",
	Long:    `XXX`,
}

var getCmd = &cobra.Command{
	Use:   "get",
	Short: "Get tools",
	Long:  `XXX`,
	Run: func(cmd *cobra.Command, args []string) {
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

		if len(args) > 1 {
			fmt.Printf("Only one tool may be specified but got %d\n", len(args))
			os.Exit(1)
		}

		if len(args) == 1 {
			tool, err := tools.GetByName(args[0])
			if err != nil {
				fmt.Printf("Error getting tool %s\n", args[0])
				os.Exit(1)
			}
			tool.Print()
			
		} else {
			tools.Print()
		}
	},
}

var describeCmd = &cobra.Command{
	Use:   "describe",
	Short: "Describe tool",
	Long:  `XXX`,
	Run: func(cmd *cobra.Command, args []string) {
		// *** add code to invoke automation end points below ***
		fmt.Println("Executing 'tool describe' placeholder command")
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
