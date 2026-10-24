"""Check the local Flux graph, resource ownership, and Kubernetes schemas."""

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

CATALOG_REVISION = "ad3b08c5045129d7bb1eeffd8e61719b2c8dd1e2"
BUILTIN_NAMESPACES = {
    "default",
    "kube-system",
    "kube-public",
    "kube-node-lease",
    "flux-system",
}


def render(*command):
    """Run a renderer and load its YAML documents."""
    result = subprocess.run(command, check=True, stdout=subprocess.PIPE, text=True)
    return [document for document in yaml.safe_load_all(result.stdout) if document]


def local_path(root, path):
    """Resolve a repository path without allowing an escape."""
    resolved = (root / path).resolve()
    if not resolved.is_relative_to(root):
        raise ValueError(f"Path leaves repository: {path}")
    return resolved


def resource_name(document):
    """Identify a resource without including its data."""
    metadata = document["metadata"]
    return "/".join(
        filter(None, [document["kind"], metadata.get("namespace"), metadata["name"]])
    )


def check_flux_bundle(root):
    """Compare controllers, CRDs, and RBAC with the declared Flux release."""
    path = root / "k8s/flux-system/gotk-components.yaml"
    documents = list(yaml.safe_load_all(path.read_text()))
    namespace = next(
        document
        for document in documents
        if document["kind"] == "Namespace"
        and document["metadata"]["name"] == "flux-system"
    )
    version = namespace["metadata"]["labels"]["app.kubernetes.io/version"]
    published = render("flux", "install", "--version", version, "--export")

    def resources(bundle):
        for document in bundle:
            if document["kind"] == "Deployment":
                for container in document["spec"]["template"]["spec"]["containers"]:
                    container["image"] = container["image"].split("@", 1)[0]
        return {resource_name(document): document for document in bundle}

    actual, expected = resources(documents), resources(published)
    changed = sorted(
        name
        for name in actual.keys() | expected.keys()
        if actual.get(name) != expected.get(name)
    )
    if changed:
        raise ValueError(
            f"Flux bundle differs from release {version}: {', '.join(changed)}. "
            f"Regenerate gotk-components.yaml with flux install --version={version} --export; "
            "keep customizations in kustomization.yaml."
        )
    print(f"Flux controllers, CRDs, and RBAC match release {version}", flush=True)


def discover(root):
    """Render the local Flux targets and retain their individual ownership."""
    pending = [("flux-system", root / "k8s/flux-system")]
    targets = {}
    declarations = {}
    while pending:
        name, directory = pending.pop()
        if name in targets:
            if targets[name]["path"] != directory:
                raise ValueError(f"Flux target {name} has conflicting paths")
            continue
        print(f"Rendering {name}: {directory.relative_to(root)}", flush=True)
        documents = render("kustomize", "build", str(directory))
        targets[name] = {"path": directory, "documents": documents}
        for document in documents:
            if not document.get("apiVersion", "").startswith(
                "kustomize.toolkit.fluxcd.io/"
            ):
                continue
            if document.get("kind") != "Kustomization":
                continue
            metadata, spec = document["metadata"], document["spec"]
            child = metadata["name"]
            if child in declarations:
                raise ValueError(f"Duplicate Flux Kustomization: {child}")
            declarations[child] = document
            source = spec["sourceRef"]
            if (
                metadata.get("namespace") != "flux-system"
                or source.get("kind") != "GitRepository"
                or source.get("name") != "flux-system"
                or source.get("namespace", "flux-system") != "flux-system"
            ):
                raise ValueError(
                    f"{child}: only the local flux-system GitRepository is supported"
                )
            transforms = {
                "postBuild",
                "patches",
                "images",
                "targetNamespace",
                "namePrefix",
                "nameSuffix",
                "components",
                "kubeConfig",
            }
            if transforms.intersection(spec):
                raise ValueError(
                    f"{child}: Flux-level rendering transformations are not supported by this check"
                )
            pending.append((child, local_path(root, spec["path"])))
    return targets, declarations


def dependency_order(declarations):
    """Validate dependencies and return their prerequisite-first order."""
    dependencies = {}
    for name, document in declarations.items():
        dependencies[name] = set()
        for dependency in document["spec"].get("dependsOn", []):
            if (
                dependency.get("namespace", "flux-system") != "flux-system"
                or dependency["name"] not in declarations
            ):
                raise ValueError(f"{name}: missing dependency {dependency}")
            dependencies[name].add(dependency["name"])
    ordered = []
    remaining = dict(dependencies)
    while remaining:
        ready = sorted(
            name for name, needs in remaining.items() if needs.issubset(ordered)
        )
        if not ready:
            raise ValueError(f"Flux dependency cycle: {', '.join(sorted(remaining))}")
        ordered.extend(ready)
        for name in ready:
            del remaining[name]
    ancestors = {}
    for name in ordered:
        ancestors[name] = set(dependencies[name])
        for dependency in dependencies[name]:
            ancestors[name].update(ancestors[dependency])
        print(f"Dependencies {name}: {', '.join(sorted(dependencies[name])) or 'none'}")
    return ancestors


def check_roots(root, targets):
    """Reject Kustomize directories that no Flux target or local base reaches."""
    reached = set()
    pending = [target["path"] for target in targets.values()]
    while pending:
        directory = pending.pop()
        if directory in reached:
            continue
        reached.add(directory)
        config = yaml.safe_load((directory / "kustomization.yaml").read_text())
        for reference in config.get("resources", []) + config.get("components", []):
            path = local_path(root, directory / reference)
            if path.is_dir():
                pending.append(path)
    for path in sorted((root / "k8s").rglob("kustomization.yaml")):
        if not path.is_relative_to(root / "k8s/charts") and path.parent not in reached:
            raise ValueError(f"Unreachable Kustomization: {path.relative_to(root)}")


def render_charts(root, targets, temporary, version):
    """Render local charts and explicitly report remote charts left unrendered."""
    for owner, target in targets.items():
        for resource in list(target["documents"]):
            if resource.get("kind") != "HelmRelease":
                continue
            spec = resource["spec"]
            chart = spec.get("chart", {}).get("spec", {})
            source = chart.get("sourceRef", {})
            if source.get("kind") != "GitRepository":
                print(f"Not rendered: upstream {resource_name(resource)}")
                continue
            if (
                source.get("name") != "flux-system"
                or source.get("namespace", resource["metadata"]["namespace"])
                != "flux-system"
            ):
                raise ValueError(
                    f"{owner}: local chart must use the flux-system GitRepository"
                )
            if spec.get("valuesFrom"):
                raise ValueError(
                    f"{owner}: local Helm valuesFrom rendering is unsupported"
                )
            name = spec.get("releaseName", resource["metadata"]["name"])
            namespace = spec.get("targetNamespace", resource["metadata"]["namespace"])
            values = temporary / "values.yaml"
            values.write_text(yaml.safe_dump(spec.get("values", {})))
            chart_path = local_path(root, chart["chart"])
            print(f"Rendering local Helm release {namespace}/{name}", flush=True)
            target["documents"].extend(
                render(
                    "helm",
                    "template",
                    name,
                    str(chart_path),
                    "--namespace",
                    namespace,
                    "--values",
                    str(values),
                    "--kube-version",
                    version,
                )
            )


def check_ownership(targets):
    """Require one visible owner for each resource and namespace."""
    owners, namespaces, secrets = {}, {}, {}
    for owner, target in targets.items():
        visible = 0
        for document in target["documents"]:
            if "sops" in document:
                if document.get("kind") == "Secret":
                    metadata = document["metadata"]
                    secrets[
                        (metadata.get("namespace", "default"), metadata["name"])
                    ] = owner
                continue
            metadata = document["metadata"]
            identity = (
                document["apiVersion"].split("/")[0]
                if "/" in document["apiVersion"]
                else "",
                document["kind"],
                metadata.get("namespace", ""),
                metadata["name"],
            )
            if identity in owners:
                raise ValueError(
                    f"{resource_name(document)}: duplicate owners {owners[identity]} and {owner}"
                )
            owners[identity] = owner
            if document["kind"] == "Namespace":
                namespaces[metadata["name"]] = owner
                if metadata["name"] not in BUILTIN_NAMESPACES and owner != "namespaces":
                    raise ValueError(
                        f"{resource_name(document)}: must belong to the namespaces target"
                    )
            if document["kind"] == "Secret":
                raise ValueError(f"{owner}: unencrypted {resource_name(document)}")
            visible += 1
        print(f"Ownership {owner}: {visible} visible resources")
    return namespaces, secrets


def pod_template(document):
    """Return the pod template for a supported workload, if present."""
    kind = document.get("kind")
    if kind == "Pod":
        return document
    if kind in {"Deployment", "StatefulSet", "DaemonSet", "Job", "ReplicaSet"}:
        return document["spec"]["template"]
    if kind == "CronJob":
        return document["spec"]["jobTemplate"]["spec"]["template"]
    return None


def secret_references(document):
    """Find the supported explicit Secret references without reading values."""
    names = set()
    if document.get("kind") == "HelmRelease":
        names.update(
            reference["name"]
            for reference in document["spec"].get("valuesFrom", [])
            if reference.get("kind", "Secret") == "Secret"
        )
    template = pod_template(document)
    if template:
        spec = template["spec"]
        names.update(
            reference["name"] for reference in spec.get("imagePullSecrets", [])
        )
        for container in spec.get("containers", []) + spec.get("initContainers", []):
            names.update(
                reference["secretRef"]["name"]
                for reference in container.get("envFrom", [])
                if "secretRef" in reference
            )
            names.update(
                env["valueFrom"]["secretKeyRef"]["name"]
                for env in container.get("env", [])
                if "secretKeyRef" in env.get("valueFrom", {})
            )
        for volume in spec.get("volumes", []):
            if "secret" in volume:
                names.add(volume["secret"]["secretName"])
            names.update(
                source["secret"]["name"]
                for source in volume.get("projected", {}).get("sources", [])
                if "secret" in source
            )
    return names


def check_prerequisites(targets, ancestors, namespaces, secrets):
    """Check ordering for visible namespaces and known encrypted Secrets."""
    for owner, target in targets.items():
        for document in target["documents"]:
            if "sops" in document:
                continue
            metadata = document["metadata"]
            namespace = metadata.get("namespace")
            required = {namespace} if namespace else set()
            if document["kind"] == "HelmRelease":
                required.add(document["spec"].get("targetNamespace", namespace))
            for name in required - BUILTIN_NAMESPACES - {None}:
                producer = namespaces.get(name)
                if producer is None:
                    raise ValueError(f"{owner}: namespace {name} is not declared")
                if producer != owner and producer not in ancestors[owner]:
                    raise ValueError(
                        f"{owner}: namespace {name} requires dependency {producer}"
                    )
            for name in secret_references(document):
                producer = secrets.get((namespace or "default", name))
                if producer and producer != owner and producer not in ancestors[owner]:
                    raise ValueError(
                        f"{owner}: Secret {namespace}/{name} requires dependency {producer}"
                    )


def check_security(targets):
    """Require explicit pod defaults or a setting-specific exception reason."""
    prefix = "security.aly.codes/exception-"
    rules = {
        "api-token",
        "service-links",
        "seccomp",
        "privilege-escalation",
        "net-raw",
        "host-network",
        "host-pid",
        "host-ipc",
        "host-port",
        "privileged",
        "host-path",
        "added-capabilities",
    }
    for owner, target in targets.items():
        if owner == "flux-system":
            continue
        for document in target["documents"]:
            if "sops" in document or not (template := pod_template(document)):
                continue
            spec = template["spec"]
            deviations = set()
            if spec.get("automountServiceAccountToken") is not False:
                deviations.add("api-token")
            if spec.get("enableServiceLinks") is not False:
                deviations.add("service-links")
            for field, rule in [
                ("hostNetwork", "host-network"),
                ("hostPID", "host-pid"),
                ("hostIPC", "host-ipc"),
            ]:
                if spec.get(field):
                    deviations.add(rule)
            if any("hostPath" in volume for volume in spec.get("volumes", [])):
                deviations.add("host-path")
            for container in spec.get("containers", []) + spec.get(
                "initContainers", []
            ):
                context = container.get("securityContext", {})
                seccomp = context.get(
                    "seccompProfile",
                    spec.get("securityContext", {}).get("seccompProfile", {}),
                )
                if seccomp.get("type") != "RuntimeDefault":
                    deviations.add("seccomp")
                if context.get("allowPrivilegeEscalation") is not False:
                    deviations.add("privilege-escalation")
                capabilities = context.get("capabilities", {})
                if "NET_RAW" in capabilities.get("add", []) or not {
                    "NET_RAW",
                    "ALL",
                }.intersection(capabilities.get("drop", [])):
                    deviations.add("net-raw")
                if capabilities.get("add"):
                    deviations.add("added-capabilities")
                if context.get("privileged"):
                    deviations.add("privileged")
                if any(port.get("hostPort") for port in container.get("ports", [])):
                    deviations.add("host-port")
            exceptions = {
                key.removeprefix(prefix): reason
                for key, reason in template.get("metadata", {})
                .get("annotations", {})
                .items()
                if key.startswith(prefix)
            }
            name = f"{owner}: {resource_name(document)}"
            for rule, reason in exceptions.items():
                if (
                    rule not in rules
                    or not isinstance(reason, str)
                    or not reason.strip()
                ):
                    raise ValueError(f"{name}: invalid exception {rule}")
            if unused := exceptions.keys() - deviations:
                raise ValueError(
                    f"{name}: unused exceptions {', '.join(sorted(unused))}"
                )
            if missing := deviations - exceptions.keys():
                raise ValueError(
                    f"{name}: unexplained security exceptions {', '.join(sorted(missing))}"
                )


def validate_schemas(targets, temporary, version):
    """Validate visible documents with pinned CRD schemas and strict failures."""
    documents = [
        document for target in targets.values() for document in target["documents"]
    ]
    encrypted = sum("sops" in document for document in documents)
    print(
        f"Excluded {encrypted} encrypted documents; Secret contents are not checked",
        flush=True,
    )
    manifests = temporary / "resources.yaml"
    manifests.write_text(
        yaml.safe_dump_all(document for document in documents if "sops" not in document)
    )
    subprocess.run(
        [
            "kubeconform",
            "-strict",
            "-summary",
            "-skip",
            "CustomResourceDefinition",
            "-kubernetes-version",
            version,
            "-schema-location",
            "default",
            "-schema-location",
            "https://raw.githubusercontent.com/datreeio/CRDs-catalog/"
            + CATALOG_REVISION
            + "/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json",
            str(manifests),
        ],
        check=True,
    )


def main():
    """Run the same credential-free checks locally and in CI."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kubernetes-version", required=True)
    parser.add_argument(
        "--flux-bundle-only",
        action="store_true",
        help="Only compare the Flux installation with its declared release",
    )
    args = parser.parse_args()
    root = Path.cwd().resolve()
    check_flux_bundle(root)
    if args.flux_bundle_only:
        return
    targets, declarations = discover(root)
    ancestors = dependency_order(declarations)
    check_roots(root, targets)
    with tempfile.TemporaryDirectory(prefix="check-k8s-") as temporary:
        temporary = Path(temporary)
        render_charts(root, targets, temporary, args.kubernetes_version)
        namespaces, secrets = check_ownership(targets)
        check_prerequisites(targets, ancestors, namespaces, secrets)
        check_security(targets)
        validate_schemas(targets, temporary, args.kubernetes_version)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, subprocess.CalledProcessError) as error:
        print(f"check-k8s: {error}", file=sys.stderr)
        sys.exit(1)
