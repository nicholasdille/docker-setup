echo "Fix filename"
mv "${target}/bin/kots" "${target}/bin/kubectl-kots"
echo "Install completion"
${binary} completion bash 2>/dev/null >"${target}/share/bash-completion/completions/${name}"
${binary} completion fish 2>/dev/null >"${target}/share/fish/vendor_completions.d/${name}.fish"
${binary} completion zsh 2>/dev/null >"${target}/share/zsh/vendor-completions/_${name}"

