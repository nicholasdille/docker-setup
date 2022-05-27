package main

import (
	"github.com/spf13/cobra"
	"github.com/spf13/cobra/doc"
)

func initTestCmd() {
	rootCmd.AddCommand(testCmd)
}

var testCmd = &cobra.Command{
	Use:     "test",
	Short:   "Test",
	RunE:    func(cmd *cobra.Command, args []string) (err error) {
		// Manpages
		header := &doc.GenManHeader{
			Title: "docker-setup",
			Section: "1",
		}
		err = doc.GenManTree(rootCmd, header, "/tmp")
		if err != nil {
			return
		}

		// Markdown
		err = doc.GenMarkdownTree(rootCmd, "/tmp")
		if err != nil {
			return
		}

		// ReST
		err = doc.GenReSTTree(rootCmd, "/tmp")
		if err != nil {
			return
		}

		// YAML
		err = doc.GenYamlTree(rootCmd, "/tmp")
		if err != nil {
			return
		}

		return nil
	},
}
