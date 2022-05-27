package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/nicholasdille/docker-setup/pkg/tool"
	"github.com/nicholasdille/docker-setup/pkg/shell"
)

var installMode string
var plan bool

func initInstallCmd() {
	rootCmd.AddCommand(installCmd)

	installCmd.Flags().StringVarP(&installMode, "mode", "m", "default", "How to install (default, list, tags, installed)")
	installCmd.Flags().BoolVarP  (&plan,        "plan", "p", false,     "Show planned installations")

	installCmd.Flags().BoolP("no-wait",         "n", false, "Skip wait before installation")
	installCmd.Flags().BoolP("skip-docs",       "s", false, "Do not install documentation for faster installation")
	installCmd.Flags().BoolP("reinstall",       "r", false, "Reinstall tools")
	installCmd.Flags().BoolP("check",           "c", false, "Abort after checking versions")
	installCmd.Flags().BoolP("no-cache",        "",  false, "Do not cache downloads")
	installCmd.Flags().BoolP("no-cron",         "",  false, "Do not create cronjob for automated updates")
}

var installCmd = &cobra.Command{
	Use:       "install [tool...]",
	Aliases:   []string{"i"},
	Short:     "Install tools",
	Long:      header + "\nInstall and update tools",
	ValidArgs: tools.GetNames(),
	Args:      cobra.OnlyValidArgs,
	Run:       func(cmd *cobra.Command, args []string) {
		var installTools tool.Tools

		if installMode == "list" {
			installTools = tools.GetByNames(args)

		} else if installMode == "tags" {
			installTools = tools.GetByTags(args)

		} else if installMode == "default" {
			installTools = tools
		}

		if plan {
			installTools.List()
		}

		return

		toolName := "docker"
		toolCacheDirectory := cacheDirectory + "/" + toolName
		toolInstallScript := toolCacheDirectory + "/install.sh"

		os.MkdirAll(toolCacheDirectory, 0755)
		err := shell.CreateScript(toolInstallScript, "pwd", "ls -l", "whoami", "printenv | sort")
		if err != nil {
			fmt.Printf("Unable to create installation script %s for %s: %s", toolInstallScript, toolName, err)
			os.Exit(1)
		}
		shell.ExecuteScript(toolInstallScript)
	},
}
