package tool

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
	
	log "github.com/sirupsen/logrus"
)

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

func (tool *Tool) ReplaceVariables(target string) {
	log.Tracef("Replacing variables for %s", tool.Name)

	//binary
	tool.Binary = 
		strings.Replace(
			strings.Replace(
				tool.Binary, "${name}", tool.Name, -1,
			), "${target}", target, -1,
		)
	if tool.Binary[:1] != "/" {
		tool.Binary = target + "/bin/" + tool.Binary
	}
			
	//check
	tool.Check = 
		strings.Replace(
			strings.Replace(
				strings.Replace(
					tool.Check, "${binary}", tool.Binary, -1,
				), "${name}", tool.Name, -1,
			), "${target}", target, -1,
		)
}

func (tool *Tool) GetStatus() (ToolStatus, error) {
	status := ToolStatus{
		Name:           tool.Name,
		BinaryPresent:  false,
		Version:        "",
		VersionMatches: false,
	}

	// Check presence of binary
	_, err := os.Stat(tool.Binary)
	if err == nil {
		status.BinaryPresent = true
	  
	} else if errors.Is(err, os.ErrNotExist) {
		status.BinaryPresent = false
	  
	} else {
		return ToolStatus{}, fmt.Errorf("Unable to check binary status: %s", err)
	}

	// Retrieve version
	if status.BinaryPresent && tool.Check != "" {
		log.Tracef("Running version check for %s: %s", tool.Name, tool.Check)
		cmd := exec.Command("/bin/bash", "-c", tool.Check + " | tr -d '\n'")
		version, err := cmd.CombinedOutput()
		if err != nil {
			return ToolStatus{}, fmt.Errorf("Unable to execute version check (%s): %s", tool.Check, err)
		}
		status.Version = string(version)
	}

	// Check version
	log.Tracef("Comparing requested version <%s> with installed version <%s>.", tool.Version, status.Version)
	if status.Version == tool.Version {
		status.VersionMatches = true
	}

	log.Tracef("Status of %s: %+v", tool.Name, status)

	return status, nil
}
