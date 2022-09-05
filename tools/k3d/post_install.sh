echo "Install completion"
${binary} completion bash >"${target}/share/bash-completion/completions/${name}"
${binary} completion fish >"${target}/share/fish/vendor_completions.d/${name}.fish"
${binary} completion zsh >"${target}/share/zsh/vendor-completions/_${name}"

