package shell

import (
	"fmt"
	"os"
	"os/exec"
)

func CreateScript(filename string, lines ...string) error {
	f, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("Unable to create or open installation script %s: %s", filename, err)
	}
	defer f.Close()

	for _, line := range lines {
		_, err := f.WriteString(line + "\n")
		if err != nil {
			return fmt.Errorf("Unable to write to installation script %s: %s", filename, err)
		}
	}

	f.Sync()
	
	return nil
}

func ExecuteScript(filename string) error {
	cmd := exec.Command("/bin/bash", filename)
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("Unable to execute installation script %s: %s", filename, err)
	}
	
	f, err := os.Create(filename + ".log")
	if err != nil {
		return fmt.Errorf("Unable to create or open installation log %s: %s", filename, err)
	}
	defer f.Close()

	_, err = f.Write(output)
	if err != nil {
		return fmt.Errorf("Unable to write to installation log %s: %s", filename, err)
	}

	f.Sync()

	return nil
}