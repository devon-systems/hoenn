"""Render Flux targets and local Helm releases, then validate their resources."""

from pathlib import Path
import subprocess
import tempfile

import yaml


CATALOG_REVISION = "ad3b08c5045129d7bb1eeffd8e61719b2c8dd1e2"
KUBERNETES_VERSION = "1.35.0"


def render(*command):
    result = subprocess.run(command, check=True, stdout=subprocess.PIPE, text=True)
    return [resource for resource in yaml.safe_load_all(result.stdout) if resource]


def main():
    root = Path.cwd().resolve()
    pending = [root / "k8s/flux-system"]
    visited = set()
    resources = []
    while pending:
        directory = pending.pop()
        directory = directory.resolve()
        if directory in visited:
            continue
        if not directory.is_relative_to(root):
            raise ValueError(f"Flux target leaves repository: {directory}")
        visited.add(directory)
        print(f"Rendering {directory.relative_to(root)}", flush=True)
        documents = render("kustomize", "build", str(directory))
        resources.extend(documents)
        for document in documents:
            if document.get("apiVersion", "").startswith("kustomize.toolkit.fluxcd.io/"):
                spec = document["spec"]
                pending.append(root / spec["path"])

    with tempfile.TemporaryDirectory(prefix="check-k8s-") as temporary:
        temporary = Path(temporary)
        for resource in list(resources):
            if resource.get("kind") != "HelmRelease":
                continue
            spec = resource["spec"]
            chart = spec.get("chart", {}).get("spec", {})
            if chart.get("sourceRef", {}).get("kind") != "GitRepository":
                continue
            chart_path = (root / chart["chart"]).resolve()
            if not chart_path.is_relative_to(root):
                raise ValueError(f"Helm chart leaves repository: {chart_path}")
            if spec.get("valuesFrom"):
                raise ValueError("Local Helm valuesFrom requires explicit rendering support")
            name = spec.get("releaseName", resource["metadata"]["name"])
            namespace = spec.get("targetNamespace", resource["metadata"]["namespace"])
            values = temporary / "values.yaml"
            values.write_text(yaml.safe_dump(spec.get("values", {})))
            print(f"Rendering local Helm release {namespace}/{name}", flush=True)
            resources.extend(render(
                "helm", "template", name, str(chart_path), "--namespace", namespace,
                "--values", str(values), "--kube-version", KUBERNETES_VERSION,
            ))

        # Some SOPS documents encrypt even kind and apiVersion. CI has no keys.
        encrypted_count = sum("sops" in resource for resource in resources)
        resources = [resource for resource in resources if "sops" not in resource]
        print(f"Excluded {encrypted_count} encrypted documents from schema validation", flush=True)
        manifests = temporary / "resources.yaml"
        manifests.write_text(yaml.safe_dump_all(resources))
        subprocess.run([
            "kubeconform", "-strict", "-summary",
            # The Kubernetes schema distribution omits CRD definitions.
            "-skip", "CustomResourceDefinition",
            "-kubernetes-version", KUBERNETES_VERSION,
            "-schema-location", "default",
            "-schema-location",
            "https://raw.githubusercontent.com/datreeio/CRDs-catalog/"
            + CATALOG_REVISION
            + "/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json",
            str(manifests),
        ], check=True)


if __name__ == "__main__":
    main()
