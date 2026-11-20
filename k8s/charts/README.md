# Terrarium charts

`capensis/` and `helix/` are copied from
[`alyraffauf/terrarium`](https://github.com/alyraffauf/terrarium/tree/af7cc226e1ca6844a5cf5bfb7b3f7a71694a0e5b)
at commit `af7cc226e1ca6844a5cf5bfb7b3f7a71694a0e5b`, from each application's
`charts/` directory. The upstream MIT license is in `LICENSE.terrarium`.

Hoenn's Kubernetes validator renders local charts from the `flux-system`
GitRepository. Keep these copies aligned with the image tags in
`k8s/capensis/release.yaml` and `k8s/helix/release.yaml` when upgrading.
Local changes disable service links and expose `nodeSelector` as a chart
value. Workload settings belong in the HelmRelease values.

`cordata/` comes from the same repository at commit
`90acb03db3f53a1850a33bac67bf1c1d9031d899`. Its image is pinned in
`k8s/cordata/release.yaml`.
