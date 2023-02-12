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
	fmt.Printf("  Description: %s\n", tool.Description)
	fmt.Printf("  Homepage: %s\n", tool.Homepage)
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

	if tool.RuntimeDependencies != nil {
		fmt.Printf("  Runtime dependencies:\n")
		for _, dep := range tool.RuntimeDependencies {
			fmt.Printf("    %s\n", dep)
		}
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