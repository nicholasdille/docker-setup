package main

import (
	"github.com/spf13/cobra"
)

func initInstallCmd() {
	rootCmd.AddCommand(installCmd)

	installCmd.Flags().BoolP("only",           "o", false, "Only install specified tools")
	installCmd.Flags().BoolP("tags",           "t", false, "Only install tools with specified tags")
	installCmd.Flags().BoolP("only-installed", "i", false, "Only process installed tools")
	installCmd.Flags().BoolP("no-wait",        "n", false, "Skip wait before installation")
	installCmd.Flags().BoolP("skip-docs",      "s", false, "Do not install documentation for faster installation")
	installCmd.Flags().BoolP("reinstall",      "r", false, "Reinstall tools")
	installCmd.Flags().BoolP("check",          "c", false, "Abort after checking versions")
	installCmd.Flags().BoolP("plan",           "p", false, "Show planned installations")
	installCmd.Flags().BoolP("no-cache",       "",  false, "Do not cache downloads")
	installCmd.Flags().BoolP("no-cron",        "",  false, "Do not create cronjob for automated updates")
}

var installCmd = &cobra.Command{
	Use:     "install [tool...]",
	Aliases: []string{"i"},
	Short:   "Install tools",
	Long:    header + "\nInstall and update tools",
	Run:     func(cmd *cobra.Command, args []string) {
		//
	},
}
