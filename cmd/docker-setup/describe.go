package main

import (
	"encoding/json"
	"fmt"
	"os"

	"gopkg.in/yaml.v3"

	"github.com/spf13/cobra"
)

func initDescribeCmd() {
	rootCmd.AddCommand(describeCmd)

	describeCmd.Flags().StringP("output", "o", "pretty", "Output options: pretty, json, yaml")
}

var describeCmd = &cobra.Command{
	Use:     "describe",
	Aliases: []string{"d"},
	Short:   "Show detailed information about tools",
	Long:    header + "\nShow detailed information about tools",
	Args:    cobra.ExactArgs(1),
	Run:     func(cmd *cobra.Command, args []string) {
		load()

		output, err := cmd.PersistentFlags().GetString("output")
		if err != nil {
			fmt.Printf("Error retrieving output flag: %s\n", err)
			os.Exit(1)
		}

		tool, err := tools.GetByName(args[0])
		if err != nil {
			fmt.Printf("Error getting tool %s\n", args[0])
			os.Exit(1)
		}

		if output == "pretty" {
			tool.Print()

		} else if output == "json" {
			data, _ := json.Marshal(tool)
			fmt.Println(string(data))

		} else if output == "yaml" {
			data, _ := yaml.Marshal(tool)
			fmt.Println(string(data))
		}
	},
}
