package main

import (
	"github.com/spf13/cobra"
	"github.com/spf13/cobra/doc"
	log "github.com/sirupsen/logrus"
)

func initTestCmd() {
	rootCmd.AddCommand(testCmd)
}

var testCmd = &cobra.Command{
	Use:     "test",
	Short:   "Test",
	Run:     func(cmd *cobra.Command, args []string) {
		var err error

		// Manpages
		header := &doc.GenManHeader{
			Title: "docker-setup",
			Section: "1",
		}
		err = doc.GenManTree(rootCmd, header, "/tmp")
		if err != nil {
			log.Fatal(err)
		}

		// Markdown
		err = doc.GenMarkdownTree(rootCmd, "/tmp")
		if err != nil {
			log.Fatal(err)
		}

		// ReST
		err = doc.GenReSTTree(rootCmd, "/tmp")
		if err != nil {
			log.Fatal(err)
		}

		// YAML
		err = doc.GenYamlTree(rootCmd, "/tmp")
		if err != nil {
			log.Fatal(err)
		}

	},
}
