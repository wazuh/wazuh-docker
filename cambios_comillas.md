
## wazuh-docker
Archivo: `.github/workflows/5_check_integration_tools.yml`
Step: **"Resolve context"** (job `prepare`)

A partir de la línea **179**, cambiar:

```yaml
            echo "pr_head_ref=${{ needs.get_pr_info.outputs.pr_head_ref }}" >> $GITHUB_OUTPUT
            echo "deployment_matrix=${{ needs.get_pr_info.outputs.deployment_matrix }}" >> $GITHUB_OUTPUT
```

por:

```yaml
            echo 'pr_head_ref=${{ needs.get_pr_info.outputs.pr_head_ref }}' >> $GITHUB_OUTPUT
            echo 'deployment_matrix=${{ needs.get_pr_info.outputs.deployment_matrix }}' >> $GITHUB_OUTPUT
```

---

## wazuh-ansible
Archivo: `.github/workflows/5_check_integration_tools.yaml`
Step: **"Resolve context"** (job `prepare`)

A partir de la línea **216**, cambiar:

```yaml
            echo "pr_head_ref=${{ needs.get_pr_info.outputs.pr_head_ref }}" >> $GITHUB_OUTPUT
            echo "deployment_matrix=${{ needs.get_pr_info.outputs.deployment_matrix }}" >> $GITHUB_OUTPUT
```

por:

```yaml
            echo 'pr_head_ref=${{ needs.get_pr_info.outputs.pr_head_ref }}' >> $GITHUB_OUTPUT
            echo 'deployment_matrix=${{ needs.get_pr_info.outputs.deployment_matrix }}' >> $GITHUB_OUTPUT
```

(Las 4 líneas siguientes del mismo `else` — `os_list`, `environment`, `commit_list`,
`issue_url` — no se tocan, ya están bien.)

---