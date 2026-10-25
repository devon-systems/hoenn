"""Regression tests for Flux controller and API version consistency."""

from copy import deepcopy
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import yaml

spec = importlib.util.spec_from_file_location(
    "check_k8s", Path(__file__).with_name("check-k8s.py")
)
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class FluxBundleTests(unittest.TestCase):
    def setUp(self):
        self.original = list(
            yaml.safe_load_all(
                Path(__file__).with_name("gotk-components.yaml").read_text()
            )
        )
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.path = self.root / "k8s/flux-system/gotk-components.yaml"
        self.path.parent.mkdir(parents=True)

    def check(self, documents):
        self.path.write_text(yaml.safe_dump_all(documents))
        with patch.object(
            checker, "render", side_effect=lambda *args: deepcopy(self.original)
        ):
            checker.check_flux_bundle(self.root)

    def test_complete_release_accepts_digest_pins(self):
        published = deepcopy(self.original)
        for document in published:
            if document["kind"] == "Deployment":
                for container in document["spec"]["template"]["spec"]["containers"]:
                    container["image"] = container["image"].split("@", 1)[0]
        actual = self.original
        self.original = published
        self.check(actual)

    def test_image_only_upgrade_is_rejected(self):
        actual = deepcopy(self.original)
        controller = next(
            document
            for document in actual
            if document["kind"] == "Deployment"
            and document["metadata"]["name"] == "notification-controller"
        )
        controller["spec"]["template"]["spec"]["containers"][0]["image"] = (
            "ghcr.io/fluxcd/notification-controller:v999.0.0"
        )
        with self.assertRaisesRegex(
            ValueError, "Deployment/flux-system/notification-controller"
        ):
            self.check(actual)

    def test_missing_api_definition_is_rejected(self):
        actual = [
            document
            for document in self.original
            if document["metadata"]["name"] != "alerts.notification.toolkit.fluxcd.io"
        ]
        with self.assertRaisesRegex(
            ValueError, "alerts.notification.toolkit.fluxcd.io"
        ):
            self.check(actual)

    def test_changed_permissions_are_rejected(self):
        actual = deepcopy(self.original)
        role = next(
            document for document in actual if document["kind"] == "ClusterRole"
        )
        role["rules"] = []
        with self.assertRaisesRegex(ValueError, "ClusterRole/"):
            self.check(actual)


class TailscaleChartTests(unittest.TestCase):
    def setUp(self):
        self.resources = {
            "requests": {"cpu": "25m", "memory": "64Mi"},
            "limits": {"memory": "128Mi"},
        }
        self.release = {
            "kind": "HelmRelease",
            "metadata": {"name": "tailscale-operator", "namespace": "flux-system"},
            "spec": {
                "chart": {
                    "spec": {"chart": "tailscale-operator", "version": "1.104.2"}
                },
                "targetNamespace": "tailscale",
                "values": {"operatorConfig": {"resources": self.resources}},
            },
        }
        self.repository = {"spec": {"url": "https://pkgs.tailscale.com/helmcharts"}}

    def check(self, resources):
        rendered = [
            {
                "kind": "Deployment",
                "spec": {
                    "template": {
                        "spec": {
                            "containers": [{"name": "operator", "resources": resources}]
                        }
                    }
                },
            }
        ]
        with (
            tempfile.TemporaryDirectory() as temporary,
            patch.object(checker, "render", return_value=rendered),
        ):
            checker.check_tailscale_chart(
                self.release, self.repository, Path(temporary)
            )

    def test_operator_resources_are_applied(self):
        self.check(self.resources)

    def test_misplaced_resources_are_rejected(self):
        self.release["spec"]["values"] = {"resources": self.resources}
        with self.assertRaisesRegex(ValueError, "values.operatorConfig.resources"):
            self.check({})

    def test_chart_ignoring_resources_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "did not apply operator resources"):
            self.check({})


if __name__ == "__main__":
    unittest.main()
