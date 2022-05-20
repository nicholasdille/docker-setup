package tool

import (
	"os"

	"gopkg.in/yaml.v2"

	"github.com/jedib0t/go-pretty/v6/table"
)

type Tool struct {
	Name    string `yaml:"name"`
	Version string `yaml:"version"`
}

type Tools struct {
	Tools []Tool `yaml:"tools"`
}

func Load(data []byte) (Tools, error) {
	var tools Tools
	
	err := yaml.Unmarshal(data, &tools)
	if err != nil {
		//
		return Tools{}, err
	}

	return tools, nil
}

func (tools *Tools) Print() {
	t := table.NewWriter()
    t.SetOutputMirror(os.Stdout)

	t.AppendHeader(table.Row{"#", "Name", "Version"})

	for index, tool := range tools.Tools {
		t.AppendRows([]table.Row{
			{index, tool.Name, tool.Version},
		})
	}

    t.Render()
}

func (tools *Tools) Find() []Tool {
	//
	return nil
}
