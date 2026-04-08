"""
Unit-level plan tests for the terraform-azurerm-container-app module.

These tests validate the Terraform plan output without deploying real
infrastructure. They are suitable for running in CI pipelines that do not
have access to an Azure subscription.
"""

import pytest


# ── Container App Environment ──────────────────────────────────────────────────

class TestContainerAppEnvironment:
    def test_environment_present_in_plan(self, basic_plan):
        """The plan must include exactly one Container App Environment."""
        resource_changes = basic_plan.resource_changes
        env_resources = [
            k for k in resource_changes
            if k.startswith("azurerm_container_app_environment")
        ]
        assert len(env_resources) == 1, (
            f"Expected 1 Container App Environment, found {len(env_resources)}"
        )

    def test_environment_action_is_create(self, basic_plan):
        """The environment resource must be planned for creation."""
        change = basic_plan.resource_changes.get(
            "azurerm_container_app_environment.this"
        )
        assert change is not None
        assert "create" in change.get("change", {}).get("actions", [])

    def test_environment_zone_redundancy_disabled(self, basic_plan):
        """Basic example should have zone redundancy disabled."""
        change = basic_plan.resource_changes.get(
            "azurerm_container_app_environment.this"
        )
        after = change["change"]["after"]
        assert after.get("zone_redundancy_enabled") is False


# ── Container Apps ─────────────────────────────────────────────────────────────

class TestContainerApps:
    def _get_app_changes(self, basic_plan):
        return {
            k: v
            for k, v in basic_plan.resource_changes.items()
            if k.startswith("azurerm_container_app.this")
        }

    def test_two_container_apps_in_plan(self, basic_plan):
        """Basic example deploys exactly two Container Apps."""
        apps = self._get_app_changes(basic_plan)
        assert len(apps) == 2, (
            f"Expected 2 Container Apps, found {len(apps)}"
        )

    def test_all_container_apps_action_is_create(self, basic_plan):
        """All Container Apps must be planned for creation."""
        for key, change in self._get_app_changes(basic_plan).items():
            actions = change.get("change", {}).get("actions", [])
            assert "create" in actions, (
                f"Container App '{key}' is not planned for creation"
            )

    def test_api_app_has_ingress(self, basic_plan):
        """The API app must have ingress configured."""
        apps = self._get_app_changes(basic_plan)
        api_app = next(
            (v for k, v in apps.items() if "api" in k), None
        )
        assert api_app is not None, "API app not found in plan"
        after = api_app["change"]["after"]
        assert after.get("ingress"), "API app has no ingress block"

    def test_worker_app_has_no_ingress(self, basic_plan):
        """The worker app must not expose ingress."""
        apps = self._get_app_changes(basic_plan)
        worker_app = next(
            (v for k, v in apps.items() if "worker" in k), None
        )
        assert worker_app is not None, "Worker app not found in plan"
        after = worker_app["change"]["after"]
        assert not after.get("ingress"), "Worker app should not have ingress"


# ── Outputs ────────────────────────────────────────────────────────────────────

class TestOutputs:
    def test_outputs_declared(self, basic_plan):
        """The basic example must declare the expected root outputs."""
        expected = {"api_fqdn", "environment_domain"}
        declared = set(basic_plan.outputs.keys())
        missing = expected - declared
        assert not missing, f"Missing outputs: {missing}"
