package main

import (
	"os"

	"github.com/spf13/cobra"
	log "github.com/sirupsen/logrus"
)

var version string = "rewrite-in-go"
var header string = `
     _             _
    | |           | |                                  _
  __| | ___   ____| |  _ _____  ____ _____ ___ _____ _| |_ _   _ ____
 / _  |/ _ \ / ___) |_/ ) ___ |/ ___|_____)___) ___ (_   _) | | |  _ \
( (_| | |_| ( (___|  _ (| ____| |        |___ | ____| | |_| |_| | |_| |
 \____|\___/ \____)_| \_)_____)_|        (___/|_____)  \__)____/|  __/
                                                                |_|
`
var logLevel string
var target string
var no_color bool

var (
	rootCmd = &cobra.Command{
		Use:     "docker-setup",
		Version: version,
		Short:   header + "The container tools installer and updater",
	}
)

func init() {
	initDockerSetup()

	initDescribeCmd()
	initGenerateCmd()
	initInstallCmd()
	initListCmd()
	initSearchCmd()
	initTagsCmd()

	initTestCmd()
}

func main() {
	rootCmd.PersistentPreRunE = func(cmd *cobra.Command, args []string) error {
		log.SetOutput(os.Stdout)
		level, err := log.ParseLevel(logLevel)
		if err != nil {
			return err
		}
		log.SetLevel(level)
		log.Debugf("Log level is now %s\n", logLevel)
		return nil
	}
	rootCmd.PersistentFlags().StringVarP(&logLevel, "log-level", "l", log.WarnLevel.String(), "Log level (trace, debug, info, warning, error)")
	rootCmd.PersistentFlags().StringVarP(&target,   "target",    "t", "/usr/local",           "Target directory")
	rootCmd.PersistentFlags().BoolVarP(  &no_color, "no-color",  "",  false,                  "Suppress colored output")

	rootCmd.Execute()
}
