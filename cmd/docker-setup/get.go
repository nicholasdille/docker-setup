package main

import (
	"os"
	"sort"

	"github.com/jedib0t/go-pretty/v6/table"
	"github.com/spf13/cobra"
)

func initGetCmd() {
	rootCmd.AddCommand(getCmd)

	getCmd.AddCommand(getToolCmd)
	getCmd.AddCommand(getTagCmd)
}

var getCmd = &cobra.Command{
	Use:     "get",
	Aliases: []string{"g"},
	Short:   "List tools and tags",
	Long:    header + "\nList tools and tags",
}

var getToolCmd = &cobra.Command{
	Use:     "tool",
	Aliases: []string{"t"},
	Short:   "List tools",
	Args:    cobra.NoArgs,
	Run:     func(cmd *cobra.Command, args []string) {
		load()

		tools.List()
	},
}

var getTagCmd = &cobra.Command{
	Use:     "tag",
	Aliases: []string{"g"},
	Short:   "List tags",
	Args:    cobra.NoArgs,
	Run:     func(cmd *cobra.Command, args []string) {
		load()

		tags := make(map[string]int)
		for _, tool := range tools.Tools {
			for _, name := range tool.Tags {
				_, exists := tags[name]
				if !exists {
					tags[name] = 0
				}
				tags[name]++
			}
		}

		keys := make([]string, 0, len(tags))
		for key := range tags {
			keys = append(keys, key)
		}
		sort.Strings(keys)

		t := table.NewWriter()
		t.SetOutputMirror(os.Stdout)

		t.AppendHeader(table.Row{"#", "Name", "# Tools"})

		for index, key := range keys {
			t.AppendRows([]table.Row{
				{index + 1, key, tags[key]},
			})
		}

		t.Render()
	},
}
