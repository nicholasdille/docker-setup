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

func replaceVariables(source string, variables []string, values []string) (result string) {
	result = source

	for index, _ := range variables {
		result = strings.Replace(result, variables[index], values[index], -1)
	}

	return
}

func (tool *Tool) ReplaceVariables(target string, arch string, alt_arch string) {
	log.Tracef("Replacing variables for %s", tool.Name)

	//binary
	tool.Binary = replaceVariables(tool.Binary,
		[]string{"${name}", "${target}"},
		[]string{tool.Name, target},
	)
	if tool.Binary[:1] != "/" {
		tool.Binary = target + "/bin/" + tool.Binary
	}
			
	//check
	tool.Check = replaceVariables(tool.Check,
		[]string{"${binary}", "${name}", "${target}"},
		[]string{tool.Binary, tool.Name, target},
	)

	//url
	for index, download := range tool.Download {
		if download.Url.Template != "" {
			tool.Download[index].Url.Template = replaceVariables(download.Url.Template,
				[]string{"${name}", "${version}", "${arch}", "${alt_arch}", "${binary}", "${target}"},
				[]string{tool.Name, tool.Version, arch,      alt_arch,      tool.Binary, target},
			)
		
		} else {
			tool.Download[index].Url.Amd64 = replaceVariables(download.Url.Amd64,
				[]string{"${name}", "${version}", "${arch}", "${alt_arch}", "${binary}", "${target}"},
				[]string{tool.Name, tool.Version, arch,      alt_arch,      tool.Binary, target},
			)
			if download.Url.Arm64 != "" {
				tool.Download[index].Url.Arm64 = replaceVariables(download.Url.Arm64,
					[]string{"${name}", "${version}", "${arch}", "${alt_arch}", "${binary}", "${target}"},
					[]string{tool.Name, tool.Version, arch,      alt_arch,      tool.Binary, target},
				)
			}
		}
	}
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

func (downloadUrl *DownloadUrl) Download(alt_arch string) (path string, err error) {
	var url string
	if downloadUrl.Template != "" {
		url = downloadUrl.Template
	
	} else {
		if alt_arch == "amd64" {
			url = downloadUrl.Amd64
		
		} else if alt_arch == "arm64" {
			url = downloadUrl.Arm64
		}
	}

	log.Tracef("Using url %s", url)

	// TODO: Download to cache
	// TODO: Return path to file in cache

	return "", nil
}

func (download *Download) Install(alt_arch string) (err error) {
	path, err := download.Url.Download(alt_arch)
	if err != nil {
		return fmt.Errorf("Error downloading: %s", err)
	}

	log.Tracef("Downloaded file is located at %s", path)

	if download.Type == "executable" {
		log.Tracef("Installing executable")

	} else if download.Type == "tarball" {
		log.Tracef("Installating tarball")

	} else if download.Type == "zip" {
		log.Trace("Installing zip")
	}

	// TODO: Use archive package

	return nil
}

func (tool *Tool) Install(alt_arch string) (err error) {
	log.Tracef("Operating on architecture %s", alt_arch)

	// TODO: Check for `install` and run instead of downloads

	for index, download := range tool.Download {
		log.Tracef("Download: %+v", download)

		err = download.Install(alt_arch)
		if err != nil {
			return fmt.Errorf("Error installing download at index %d (%+v): %s", index, download, err)
		}
	}

	// TODO: Check for `post_install`

	return nil
}
