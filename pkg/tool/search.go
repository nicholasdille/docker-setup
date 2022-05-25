package tool

import (
	"fmt"
	"regexp"
)

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