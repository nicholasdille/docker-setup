package main

import (
	"fmt"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func initInspectCmd() {
	rootCmd.AddCommand(inspectCmd)
}

var inspectCmd = &cobra.Command{
	Use:       "inspect",
	Short:     "Inspect tool",
	Long:      header + "\nInspect tools",
	Args:      cobra.ExactArgs(1),
	ValidArgs: tools.GetNames(),
	PreRunE: func(cmd *cobra.Command, args []string) error {
		if fileExists(prefix + "/" + metadataFile) {
			log.Tracef("Loaded metadata file from %s", prefix+"/"+metadataFile)
			loadMetadata()
		}

		return nil
	},
	RunE: func(cmd *cobra.Command, args []string) error {
		assertMetadataFileExists()
		assertMetadataIsLoaded()

		tool, err := tools.GetByName(args[0])
		if err != nil {
			return fmt.Errorf("error getting tool %s", args[0])
		}
		tool.ReplaceVariables(prefix+target, arch, alt_arch)

		fmt.Printf("%s Inspecting %s %s\n", emoji_tool, tool.Name, tool.Version)
		err = tool.Inspect(registryImagePrefix, alt_arch)
		if err != nil {
			return fmt.Errorf("unable to inspect %s: %s", tool.Name, err)
		}

		return nil
	},
}
