package tool

import (
	"fmt"
	"os"

	"github.com/jedib0t/go-pretty/v6/table"
)

func (tool *Tool) List() {
	t := table.NewWriter()
	t.SetOutputMirror(os.Stdout)

	t.AppendHeader(table.Row{"#", "Name", "Version"})

	t.AppendRows([]table.Row{
		{1, tool.Name, tool.Version},
	})

	t.Render()
}

func (tools *Tools) List() {
	t := table.NewWriter()
	t.SetOutputMirror(os.Stdout)

	t.AppendHeader(table.Row{"#", "Name", "Version"})

	for index, tool := range tools.Tools {
		t.AppendRows([]table.Row{
			{index + 1, tool.Name, tool.Version},
		})
	}

	t.Render()
}

func (tools *Tools) ListWithStatus(toolStatus map[string]ToolStatus) {
	t := table.NewWriter()
	t.SetOutputMirror(os.Stdout)

	t.AppendHeader(table.Row{"#", "Name", "Version", "Binary present", "Installed version", "Version matches"})

	for index, tool := range tools.Tools {
		status := toolStatus[tool.Name]
		t.AppendRows([]table.Row{
			{index + 1, tool.Name, tool.Version, status.BinaryPresent, status.Version, status.VersionMatches},
		})
	}

	t.Render()
}

func (tool *Tool) Print() {
	fmt.Printf("\n")
	fmt.Printf("Name: %s\n", tool.Name)
	fmt.Printf("  Version: %s\n", tool.Version)

	if tool.Binary != "" {
		fmt.Printf("  Binary: %s\n", tool.Binary)
	}

	if tool.Check != "" {
		fmt.Printf("  Check: %s\n", tool.Check)
	}

	fmt.Printf("  Tags:\n")
	for _, tag := range tool.Tags {
		fmt.Printf("    %s\n", tag)
	}

	fmt.Printf("  Needs:\n")
	for _, dep := range tool.Needs {
		fmt.Printf("    %s\n", dep)
	}

	if tool.Download != nil {
		fmt.Printf("  Downloads:\n")
		for _, download := range tool.Download {
			fmt.Printf("    Type: %s\n", download.Type)

			if download.Url.Template != "" {
				fmt.Printf("      Url (template): %s\n", download.Url.Template)

			} else {
				fmt.Printf("      Url (amd64): %s\n", download.Url.Amd64)
				if download.Url.Arm64 != "" {
					fmt.Printf("      Url (arm64): %s\n", download.Url.Arm64)
				}
			}

			//
		}
	}

	if tool.InstallBlock != "" {
		fmt.Printf("  Install: (provided)\n")
	}

	if tool.PostInstallBlock != "" {
		fmt.Printf("  Post install: (provided)\n")
	}
}

func (tools *Tools) Describe(name string) error {
	for _, tool := range tools.Tools {
		if tool.Name == name {
			fmt.Printf("%+v\n", tool)
			return nil
		}
	}

	return fmt.Errorf("Tool named %s not found", name)
}