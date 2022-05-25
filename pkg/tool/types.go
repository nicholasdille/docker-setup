package tool

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