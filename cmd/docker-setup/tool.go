package main

import (
	"encoding/json"
	"fmt"
	"os"

	"gopkg.in/yaml.v3"

	"github.com/spf13/cobra"

	"github.com/nicholasdille/docker-setup/pkg/tool"
)

func initToolCmd() {
	rootCmd.AddCommand(toolCmd)

	toolCmd.AddCommand(toolGetCmd)
	toolCmd.AddCommand(toolDescribeCmd)
	toolCmd.AddCommand(toolSearchCmd)
	toolCmd.AddCommand(toolGenerateCmd)

	toolDescribeCmd.Flags().StringP("output", "o", "pretty", "Output options: pretty, json, yaml")

	toolSearchCmd.Flags().BoolP("only-names", "", false, "Search only in names")
	toolSearchCmd.Flags().BoolP("no-names", "n", false, "Do not search in names")
	toolSearchCmd.Flags().BoolP("only-tags", "", false, "Search only on tags")
	toolSearchCmd.Flags().BoolP("no-tags", "t", false, "Do not search in tags")
	toolSearchCmd.Flags().BoolP("only-deps", "", false, "Search only in dependencies")
	toolSearchCmd.Flags().BoolP("no-deps", "d", false, "Do not search in dependencies")
}

var tools tool.Tools

func load() {
	filename, err := rootCmd.PersistentFlags().GetString("file")
	if err != nil {
		fmt.Printf("Error retrieving file flag: %s\n", err)
		os.Exit(1)
	}

	tools, err = tool.LoadFromFile(filename)
	if err != nil {
		fmt.Printf("Error loading from file %s: %s\n", filename, err)
		os.Exit(1)
	}
}

var toolCmd = &cobra.Command{
	Use:     "tool",
	Aliases: []string{"t"},
	Short:   "Work with tools",
}

var toolGetCmd = &cobra.Command{
	Use:   "get",
	Short: "Get tools",
	Run: func(cmd *cobra.Command, args []string) {
		load()

		if len(args) > 1 {
			fmt.Printf("Only one tool may be specified but got %d\n", len(args))
			os.Exit(1)
		}

		if len(args) == 1 {
			tool, err := tools.GetByName(args[0])
			if err != nil {
				fmt.Printf("Error getting tool %s\n", args[0])
				os.Exit(1)
			}
			tool.List()
			
		} else {
			tools.List()
		}
	},
}

var toolDescribeCmd = &cobra.Command{
	Use:   "describe",
	Short: "Describe tool",
	Run: func(cmd *cobra.Command, args []string) {
		load()

		if len(args) != 1 {
			fmt.Println("You must specify exactly one tool")
			os.Exit(1)

		} else {

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
		}
	},
}

var toolSearchCmd = &cobra.Command{
	Use:   "search",
	Short: "Search for tool",
	Run: func(cmd *cobra.Command, args []string) {
		load()

		if len(args) != 1 {
			fmt.Println("You must specify exactly one tool")
			os.Exit(1)

		} else {
			onlySearchInName, err := cmd.Flags().GetBool("only-names")
			if err != nil {
				fmt.Printf("Error retrieving only-names flag: %s\n", err)
				os.Exit(1)
			}
			noSearchInName, err := cmd.Flags().GetBool("no-names")
			if err != nil {
				fmt.Printf("Error retrieving no-names flag: %s\n", err)
				os.Exit(1)
			}
			onlySearchInTags, err := cmd.Flags().GetBool("only-tags")
			if err != nil {
				fmt.Printf("Error retrieving only-tags flag: %s\n", err)
				os.Exit(1)
			}
			noSearchInTags, err := cmd.Flags().GetBool("no-tags")
			if err != nil {
				fmt.Printf("Error retrieving no-tags flag: %s\n", err)
				os.Exit(1)
			}
			onlySearchInDeps, err := cmd.Flags().GetBool("only-deps")
			if err != nil {
				fmt.Printf("Error retrieving only-deps flag: %s\n", err)
				os.Exit(1)
			}
			noSearchInDeps, err := cmd.Flags().GetBool("no-deps")
			if err != nil {
				fmt.Printf("Error retrieving no-deps flag: %s\n", err)
				os.Exit(1)
			}

			if onlySearchInName && noSearchInName {
				fmt.Printf("Error: Cannot process only-names and no-names at the same time\n")
				os.Exit(1)
			}
			if onlySearchInTags && noSearchInTags {
				fmt.Printf("Error: Cannot process only-tags and no-tags at the same time\n")
				os.Exit(1)
			}
			if onlySearchInDeps && noSearchInDeps {
				fmt.Printf("Error: Cannot process only-deps and no-deps at the same time\n")
				os.Exit(1)
			}

			if (onlySearchInName && onlySearchInTags) ||
			   (onlySearchInName && onlySearchInDeps) ||
			   (onlySearchInTags && onlySearchInDeps) {
				fmt.Printf("Error: Can only process one of only-names, only-tags and only-deps at the same time\n")
				os.Exit(1)
			}

			results := tools.Find(
				args[0],
				! noSearchInName && ! onlySearchInTags && ! onlySearchInDeps,
				! noSearchInTags && ! onlySearchInName && ! onlySearchInDeps,
				! noSearchInDeps && ! onlySearchInName && ! onlySearchInTags,
			)
			if len(results.Tools) == 0 {
				fmt.Printf("No tools found for term %s\n", args[0])

			} else {
				results.List()
			}
		}
	},
}

var toolGenerateCmd = &cobra.Command{
	Use:   "generate",
	Short: "Generate definition",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(`

tools:

# Predefined variables:
# ${name}       Name of the tool
# ${version}    Version of the tool
# ${binary}     Path and name of binary
# ${arch}       x86_64 or aarch64
# ${alt_arch}   amd64 or arm64

- name: foo
  version: 1.2.3

  # Optional:
  # Name of binary if it differs from the name
  # Relative paths will be prepended with ${target}/bin
  #binary: bar

  # Optional:
  # Version check output must match version field
  #check: ${binary} --version | cut -d' ' -f2

  # Optional:
  # Specified flags must set on the command line like --flag-foo
  # For every flag, a matching not-foo is created to define conflicts
  # See docker-compose and docker-compose-v1
  #flags:
  #- foo

  # Optional:
  # Other tools which must be installed before this one
  #needs:
  #- docker

  # Tags to catagorize tool into
  # Tools tagged with "default" will be installed if nothing else is specified
  tags:
  - docker

  # Specify which resources to download and where to place them
  # Resources require an URL which can be:
  # - A template if the URL can be used for both platforms
  # - Selarate URLs for amd64 and optionally arm64
  download:
  - url:

      # Use template if possible
      template: https://someserver.domain.com/foo/${version}/file-${alt_arch}.tar.gz
	  # Alternative to template
	  #x86_64: https://someserver.domain.com/foo/${version}/file.tar.gz
	  # Optional:
	  # Specify URL for arm64
	  #aarch64: https://someserver.domain.com/foo/${version}/file-arm64.tar.gz

	  # Type of resource
	  # - tarball
	  # - executable
	  # - zip
	  type: tarball

	  # Optional:
	  # Where to install files to
	  #path: ${target}/bin

	  # Optional:
	  # How many components to strip from path
	  #strip: 1

	  # Optional:
	  # Which files to extract
	  #files:
	  #- foo

  - url:
      template: https://someserver.domain.com/bar/${version}/file-${alt_arch}
	  type: executable
	  # Optional:
	  # Where to install files to
	  #path: ${target}/bin/blarg

  - url:
      template: https://someserver.domain.com/baz/${version}/file-${alt_arch}.zip
	  type: zip
	  # Mandatory: Specify which files to extract
	  files:
	  - baz
	  # Optional:
	  # Where to install files to
	  #path: ${target}/bin/blubb
	  # strip is only supported for tarball

  # Alternative to "download" if an installation script is required
  #install: |
  #  printenv | sort

  # Optional:
  # Commands to execute after "download" or "install"
  #post_install: |
  #  printenv | sort
		`)
	},
}
