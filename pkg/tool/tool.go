package tool

import (
	"fmt"
	"io/ioutil"
	"os"
	"regexp"

	"gopkg.in/yaml.v3"

	"github.com/jedib0t/go-pretty/v6/table"
)

type DownloadUrl struct {
	Amd64    string `yaml:"x86_64"`
	Arm64    string `yaml:"aarch64"`
	Template string `yaml:"template"`
}

type Download struct {
	Url   DownloadUrl `yaml:"url"`
	Type  string      `yaml:"type"`
	Path  string      `yaml:"path"`
	Strip string      `yaml:"strip"`
	Files []string    `yaml:"files"`
}

type Tool struct {
	Name        string     `yaml:"name"`
	Version     string     `yaml:"version"`
	Binary      string     `yaml:"binary"`
	Check       string     `yaml:"check,omitempty"`
	Tags        []string   `yaml:"tags"`
	Needs       []string   `yaml:"needs"`
	Download    []Download `yaml:"download"`
	Install     string     `yaml:"install"`
	PostInstall string     `yaml:"post_install"`
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
		return Tools{}, err
	}

	for index, tool := range tools.Tools {
		if tool.Binary == "" {
			tools.Tools[index].Binary = fmt.Sprintf("${target}/bin/%s", tool.Name)
		}
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

func (tools *Tools) GetByTag(tagName string) *Tools {
	var toolList Tools

	for _, tool := range tools.Tools {
		if tool.HasTag(tagName) {
			toolList.Tools = append(toolList.Tools, tool)
		}
	}

	return &toolList
}

func (tool *Tool) MatchesName(term string) bool {
	match, err := regexp.MatchString(term, tool.Name)
	return err == nil && match
}

func (tool *Tool) HasTag(term string) bool {
	for _, tag := range tool.Tags {
		if tag == term {
			return true
		}
	}

	return false
}

func (tool *Tool) MatchesTag(term string) bool {
	for _, tag := range tool.Tags {
		match, err := regexp.MatchString(term, tag)
		if err == nil && match {
			return true
		}
	}
	return false
}

func (tool *Tool) HasDependency(term string) bool {
	for _, dep := range tool.Needs {
		if dep == term {
			return true
		}
	}

	return false
}

func (tool *Tool) MatchesDependency(term string) bool {
	for _, dep := range tool.Needs {
		match, err := regexp.MatchString(term, dep)
		if err == nil && match {
			return true
		}
	}
	return false
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

	if tool.Install != "" {
		fmt.Printf("  Install: (provided)\n")
	}

	if tool.PostInstall != "" {
		fmt.Printf("  Post install: (provided)\n")
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

func (tools *Tools) Find(term string, searchInName bool, searchInTags bool, searchInDeps bool) Tools {
	var results Tools = Tools{}

	for _, tool := range tools.Tools {
		matches := false

		if searchInName && tool.MatchesName(term) {
			matches = true
		}

		for _, tag := range tool.Tags {
			match, err := regexp.MatchString(term, tag)
			if err == nil && searchInTags && match {
				matches = true
			}
		}

		for _, dep := range tool.Needs {
			match, err := regexp.MatchString(term, dep)
			if err == nil && searchInDeps && match {
				matches = true
			}
		}

		if matches {
			results.Tools = append(results.Tools, tool)
		}
	}

	return results
}
