package tool

import (
	"fmt"
	"io/ioutil"
	"os"

	"gopkg.in/yaml.v3"

	"github.com/jedib0t/go-pretty/v6/table"
)

type Tool struct {
	Name    string   `yaml:"name"`
	Version string   `yaml:"version"`
	Tags    []string `yaml:"tags"`
}

type Tools struct {
	Tools []Tool `yaml:"tools"`
}

func LoadFromFile(filename string) (Tools, error) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return Tools{}, fmt.Errorf("Error loading file contents: %s\n", err)
	}

	tools, err := LoadFromBytes(data)
	if err != nil {
		return Tools{}, fmt.Errorf("Error loading data: %s\n", err)
	}

	return tools, nil
}

func LoadFromBytes(data []byte) (Tools, error) {
	var tools Tools
	
	err := yaml.Unmarshal(data, &tools)
	if err != nil {
		//
		return Tools{}, err
	}

	return tools, nil
}

func (tools *Tools) GetByName(name string) (*Tool, error) {
	for _, tool := range tools.Tools {
		if tool.Name == name {
			return &tool, nil
		}
	}

	return nil, fmt.Errorf("Tool named %s not found", name)
}

func (tools *Tools) GetByTag(tagName string) (*Tools) {
	var toolList Tools

	for _, tool := range tools.Tools {
		for _, tag := range tool.Tags {
			if tag == tagName {
				toolList.Tools = append(toolList.Tools, tool)
			}
		}
	}

	return &toolList
}

func (tool *Tool) List() {
	t := table.NewWriter()
    t.SetOutputMirror(os.Stdout)

	t.AppendHeader(table.Row{"#", "Name", "Version"})

	t.AppendRows([]table.Row{
		{1, tool.Name, tool.Version},
	})

    t.Render()
}

func (tool *Tool) Print() {
	fmt.Printf("Name: %s\n", tool.Name)
	fmt.Printf("  Version: %s\n", tool.Version)
	fmt.Printf("  Tags:\n")
	for _, tag := range tool.Tags {
		fmt.Printf("    %s\n", tag)
	}
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

func (tools *Tools) Describe(name string) error {
	for _, tool := range tools.Tools {
		if tool.Name == name {
			fmt.Printf("%+v\n", tool)
			return nil
		}
	}

	return fmt.Errorf("Tool named %s not found", name)
}

func (tools *Tools) Find() []Tool {
	//
	return nil
}
