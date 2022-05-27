package main

import (
	"os"

	"github.com/spf13/cobra"
	log "github.com/sirupsen/logrus"
	//"github.com/fatih/color"

	"github.com/nicholasdille/docker-setup/pkg/tool"
	"github.com/nicholasdille/docker-setup/pkg/shell"
)

var installMode string
var plan bool
var toolStatus map[string]tool.ToolStatus = make(map[string]tool.ToolStatus)

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
		var requestedTools tool.Tools
		var plannedTools tool.Tools

		//var check_mark string = "✓" // Unicode=\u2713 UTF-8=\xE2\x9C\x93 (https://www.compart.com/de/unicode/U+2713)
		//var cross_mark string = "✗" // Unicode=\u2717 UTF-8=\xE2\x9C\x97 (https://www.compart.com/de/unicode/U+2717)

		log.Tracef("Found %d argument(s): %+v", len(args), args)
		if installMode == "list" || installMode == "tags" {
			if len(args) == 0 {
				log.Error("You must specify at least one tool for mode list or tags.")
				os.Exit(1)
			}
		}

		if installMode == "list" {
			requestedTools = tools.GetByNames(args)

			for index, tool := range requestedTools.Tools {
				log.Tracef("Getting status for requested tool %s", tool.Name)
				requestedTools.Tools[index].ReplaceVariables(target)

				status, err := requestedTools.Tools[index].GetStatus()
				if err != nil {
					log.Errorf("Unable to determine status of %s: %s", tool.Name, err)
					os.Exit(1)
				}
				
				toolStatus[tool.Name] = status
			}

		} else if installMode == "tags" {
			requestedTools = tools.GetByTags(args)

		} else if installMode == "default" {
			requestedTools = tools

		} else if installMode == "only-installed" {
			for index, tool := range tools.Tools {
				tools.Tools[index].ReplaceVariables(target)

				status, err := tools.Tools[index].GetStatus()
				if err != nil {
					log.Errorf("Unable to determine status of %s: %s", tool.Name, err)
					os.Exit(1)
				}

				toolStatus[tool.Name] = status
			}

			//
		}

		log.Debugf("Requested %d tool(s)", len(requestedTools.Tools))

		for _, tool := range requestedTools.Tools {
			err := tools.ResolveDependencies(&plannedTools, tool.Name)
			if err != nil {
				log.Errorf("Unable to resolve dependencies for %s: %s", tool.Name, err)
				os.Exit(1)
			}
		}

		log.Debugf("Planned %d tool(s)", len(plannedTools.Tools))

		if plan {
			//plannedTools.List()
		}

		return

		toolName := "docker"
		toolCacheDirectory := cacheDirectory + "/" + toolName
		toolInstallScript := toolCacheDirectory + "/install.sh"

		os.MkdirAll(toolCacheDirectory, 0755)
		err := shell.CreateScript(toolInstallScript, "pwd", "ls -l", "whoami", "printenv | sort")
		if err != nil {
			log.Errorf("Unable to create installation script %s for %s: %s", toolInstallScript, toolName, err)
			os.Exit(1)
		}
		shell.ExecuteScript(toolInstallScript)
	},
}
