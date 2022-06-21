package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/cobra/doc"

	"github.com/nicholasdille/docker-setup/pkg/archive"
)

func initTestCmd() {
	rootCmd.AddCommand(testCmd)
}

var testCmd = &cobra.Command{
	Use:     "test",
	Short:   "Test",
	RunE:    func(cmd *cobra.Command, args []string) (err error) {
		// Test archive operations
		r, err := os.Open("./file.tar.gz")
		if err != nil {
			fmt.Printf("ERROR: %s", err)
		}
		err = archive.Untargz("/tmp", r)
		r.Close()
		if err != nil {
			fmt.Printf("ERROR: %s", err)
		}
		archive.Unzip("./file.zip", "/tmp")
		r, err = os.Open("./file.tar.xz")
		if err != nil {
			fmt.Printf("ERROR: %s", err)
		}
		err = archive.Untarxz("/tmp", r)
		r.Close()
		if err != nil {
			fmt.Printf("ERROR: %s", err)
		}

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
